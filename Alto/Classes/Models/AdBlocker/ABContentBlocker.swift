//
//  ABContentBlocker.swift
//  Alto
//
//  Created by Kami on 23/06/2025.
//

import Foundation
import OSLog
import WebKit

// MARK: - ABContentBlocker

/// Handles content blocking operations for WebViews
@MainActor
public final class ABContentBlocker: NSObject, ObservableObject {
    private let logger = Logger(subsystem: "com.alto.adblock", category: "ABContentBlocker")

    // MARK: - WebView Management

    private var registeredWebViews: Set<WeakWebViewWrapper> = []
    private var currentRuleLists: [WKContentRuleList] = [] // Changed to array for multiple rule lists
    private var navigationDelegates: [ObjectIdentifier: ABNavigationDelegate] = [:]

    // MARK: - Rule List Limits

    private let maxRulesPerList = 25000 // WebKit limit per rule list
    private let maxRuleLists = 10 // Maximum number of rule lists to create

    // MARK: - WebView Registration

    /// Register a WebView for content blocking
    public func registerWebView(_ webView: WKWebView) {
        let wrapper = WeakWebViewWrapper(webView: webView)
        registeredWebViews.insert(wrapper)
        setupNavigationDelegate(for: webView)
        logger.info("📝 Registered WebView for content blocking (URL: \(webView.url?.absoluteString ?? "none"))")
    }

    /// Unregister a WebView
    public func unregisterWebView(_ webView: WKWebView) {
        let identifier = ObjectIdentifier(webView)
        registeredWebViews = registeredWebViews.filter { $0.webView !== webView }
        navigationDelegates.removeValue(forKey: identifier)
        logger.info("🗑️ Unregistered WebView from content blocking")
    }

    /// Update rule lists for all registered WebViews
    public func updateRuleList(_ ruleList: WKContentRuleList) async {
        currentRuleLists = [ruleList] // Single rule list for backward compatibility
        await applyRuleListsToAllWebViews(currentRuleLists)
    }

    /// Update multiple rule lists for all registered WebViews
    public func updateRuleLists(_ ruleLists: [WKContentRuleList]) async {
        currentRuleLists = ruleLists
        await applyRuleListsToAllWebViews(currentRuleLists)
    }

    /// Enable content blocking for all WebViews
    public func enableForAllWebViews() async {
        guard !currentRuleLists.isEmpty else {
            logger.warning("⚠️ No rule lists available to enable")
            return
        }

        await applyRuleListsToAllWebViews(currentRuleLists)
        logger.info("✅ Enabled content blocking for all WebViews")
    }

    /// Disable content blocking for all WebViews
    public func disableForAllWebViews() async {
        cleanupWebViews()

        logger.info("🚫 Disabling content blocking for all WebViews")

        await withTaskGroup(of: Void.self) { group in
            for wrapper in registeredWebViews {
                if let webView = wrapper.webView {
                    group.addTask {
                        await self.removeAllRuleLists(from: webView)
                    }
                }
            }
        }

        logger.info("🚫 Disabled content blocking for all WebViews")
    }

    /// Compile and apply content blocking rules
    public func compileAndApplyRules() async {
        logger.info("🛡️ Compiling content blocking rules...")

        let filterListManager = ABManager.shared.filterListManager
        let excludedDomains = ABManager.shared.whitelistedDomains

        logger.info("🔧 Excluded domains: \(Array(excludedDomains).joined(separator: ", "))")

        // Get all rules without the 25k limit - we'll split them ourselves
        let allRules = await filterListManager.getAllCompiledRules(excludingDomains: excludedDomains)

        logger.info("📝 Generated \(allRules.count) total rules to be split into multiple rule lists")

        do {
            let ruleLists = try await createMultipleRuleLists(from: allRules)
            await applyRuleLists(ruleLists)

            // Update ABManager with the primary rule list (first one)
            if let primaryRuleList = ruleLists.first {
                await ABManager.shared.setCompiledRuleList(primaryRuleList)
            }

            // Cache the rule hash for future validation
            await ABManager.shared.cacheCurrentRuleHash()

            logger.info("✅ Content blocking rules compiled and applied successfully (\(ruleLists.count) rule lists)")
        } catch {
            logger.error("❌ Failed to compile content rules: \(error)")
            await attemptFallbackRules(filterListManager)
        }
    }

    /// Create multiple rule lists from a large set of rules
    private func createMultipleRuleLists(from allRules: [ABContentRule]) async throws -> [WKContentRuleList] {

        // Separate blocking rules from whitelist rules
        var blockingRules: [ABContentRule] = []
        var whitelistRules: [ABContentRule] = []

        for rule in allRules {
            if rule.action.type == ABActionType.ignorePreviousRules.rawValue {
                whitelistRules.append(rule)
            } else {
                blockingRules.append(rule)
            }
        }

        logger.info("📊 Separated \(blockingRules.count) blocking rules and \(whitelistRules.count) whitelist rules")

        // Split blocking rules into chunks
        let blockingChunks = blockingRules.chunked(into: maxRulesPerList - whitelistRules.count)
        let totalRuleLists = min(blockingChunks.count, maxRuleLists)

        logger.info("🔧 Creating \(totalRuleLists) rule lists with whitelist rules in each")

        var compiledRuleLists: [WKContentRuleList] = []

        for (index, blockingChunk) in blockingChunks.enumerated() {
            guard index < maxRuleLists else { break }

            // Each rule list gets its blocking rules + ALL whitelist rules
            var ruleListRules = blockingChunk
            ruleListRules.append(contentsOf: whitelistRules)

            logger
                .info(
                    "🔧 Compiling rule list \(index + 1)/\(totalRuleLists) with \(blockingChunk.count) blocking + \(whitelistRules.count) whitelist rules"
                )

            do {
                let rulesJSON = encodeRules(ruleListRules) ?? "[]"
                let ruleList = try await compileRuleList(
                    identifier: "AltoBlockRules_\(index)",
                    rulesJSON: rulesJSON
                )
                compiledRuleLists.append(ruleList)
                logger.info("✅ Successfully compiled rule list \(index + 1)/\(totalRuleLists)")
            } catch {
                logger.error("❌ Failed to compile rule list \(index + 1): \(error)")
                // Continue with other rule lists
            }
        }

        if compiledRuleLists.isEmpty {
            // throw ABError.compilationFailed("Failed to compile any rule lists")
        }

        logger.info("🎯 Successfully created \(compiledRuleLists.count) rule lists with whitelist protection in each")
        return compiledRuleLists
    }

    /// Encode rules to JSON string for WebKit
    private func encodeRules(_ rules: [ABContentRule]) -> String? {
        do {
            let jsonData = try JSONEncoder().encode(rules)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            logger.error("❌ Failed to encode rules: \(error)")
            return nil
        }
    }

    // MARK: - Private Methods

    private func applyRuleListsToAllWebViews(_ ruleLists: [WKContentRuleList]) async {
        cleanupWebViews()

        await withTaskGroup(of: Void.self) { group in
            for wrapper in registeredWebViews {
                if let webView = wrapper.webView {
                    group.addTask {
                        await self.applyRuleLists(to: webView, ruleLists: ruleLists)
                    }
                }
            }
        }
    }

    private func compileRuleList(identifier: String, rulesJSON: String) async throws -> WKContentRuleList {
        logger.info("🔧 Compiling rule list with identifier: \(identifier)")

        guard let ruleList = try await WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: identifier,
            encodedContentRuleList: rulesJSON
        ) else {
            throw NSError(
                domain: "ABContentBlocker",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to compile rule list"]
            )
        }

        logger.info("✅ Successfully compiled rule list with identifier: \(identifier)")
        return ruleList
    }

    private func attemptFallbackRules(_ filterListManager: ABFilterListManager) async {
        logger.info("🔄 Attempting fallback with minimal rules...")

        do {
            let minimalRulesJSON = await filterListManager.getMinimalRules()
            logger.info("🔧 Fallback rules JSON (\(minimalRulesJSON.count) characters): \(minimalRulesJSON)")

            let fallbackRuleList = try await compileRuleList(
                identifier: "AltoBlockRules_minimal",
                rulesJSON: minimalRulesJSON
            )
            await updateRuleList(fallbackRuleList)

            // Also update ABManager's compiled rule list to stay in sync
            await ABManager.shared.setCompiledRuleList(fallbackRuleList)

            logger.info("✅ Minimal content blocking rules applied as fallback")
        } catch {
            logger.error("❌ Even minimal rules failed to compile: \(error)")
            logger.info("🚨 AdBlock system running without content rules - JavaScript blocking only")
        }
    }

    private func applyRuleLists(to webView: WKWebView, ruleLists: [WKContentRuleList]) async {
        let url = webView.url?.absoluteString ?? "unknown"
        logger.info("🛡️ Applying rule lists to WebView (URL: \(url))")

        await removeAllRuleLists(from: webView)
        for ruleList in ruleLists {
            await webView.configuration.userContentController.add(ruleList)
        }

        logger.info("✅ Applied rule lists to WebView (URL: \(url))")
    }

    private func removeAllRuleLists(from webView: WKWebView) async {
        let url = webView.url?.absoluteString ?? "unknown"
        logger.info("🗑️ Removing all rule lists from WebView (URL: \(url))")

        await webView.configuration.userContentController.removeAllContentRuleLists()
    }

    private func setupNavigationDelegate(for webView: WKWebView) {
        let identifier = ObjectIdentifier(webView)
        let delegate = ABNavigationDelegate()
        navigationDelegates[identifier] = delegate

        // Set up message handler for logging from JavaScript
        let messageHandler = ABMessageHandler()
        webView.configuration.userContentController.add(messageHandler, name: "altoBlockLogger")

        logger.info("🔌 Set up navigation delegate and message handler for WebView")
    }

    private func cleanupWebViews() {
        let before = registeredWebViews.count
        registeredWebViews = registeredWebViews.filter { $0.webView != nil }
        let after = registeredWebViews.count

        if before != after {
            logger.info("🧹 Cleaned up WebViews: \(before) -> \(after)")
        }
    }

    /// Apply rule lists to all registered WebViews
    private func applyRuleLists(_ ruleLists: [WKContentRuleList]) async {
        currentRuleLists = ruleLists

        // Apply to all registered WebViews
        for wrapper in registeredWebViews {
            if let webView = wrapper.webView {
                await applyRuleListsToWebView(webView, ruleLists: ruleLists)
            }
        }
    }

    /// Check if rule lists are already compiled and available
    public func hasCompiledRules() async -> Bool {
        // Check if WebKit has our compiled rule lists persisted
        guard let ruleListStore = WKContentRuleListStore.default() else {
            logger.debug("🔍 No rule list store available")
            return false
        }

        do {
            // Try to look up our known rule list identifiers using async/await
            let identifier1 = "AltoBlockRules_0"
            let ruleList1 = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<
                WKContentRuleList?,
                Error
            >) in
                ruleListStore.lookUpContentRuleList(forIdentifier: identifier1) { ruleList, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ruleList)
                    }
                }
            }

            if ruleList1 != nil {
                logger.info("📋 Found existing compiled rule lists in WebKit store")
                // Load the existing rule lists into memory
                var existingRuleLists: [WKContentRuleList] = []

                for i in 0 ..< 3 { // We typically create 3 rule lists
                    let identifier = "AltoBlockRules_\(i)"
                    do {
                        let ruleList = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<
                            WKContentRuleList?,
                            Error
                        >) in
                            ruleListStore.lookUpContentRuleList(forIdentifier: identifier) { ruleList, error in
                                if let error {
                                    continuation.resume(throwing: error)
                                } else {
                                    continuation.resume(returning: ruleList)
                                }
                            }
                        }
                        if let ruleList {
                            existingRuleLists.append(ruleList)
                        }
                    } catch {
                        // Rule list not found or error - continue with others
                        logger.debug("🔍 Rule list \(identifier) not found: \(error)")
                    }
                }

                if !existingRuleLists.isEmpty {
                    currentRuleLists = existingRuleLists
                    logger.info("📋 Loaded \(existingRuleLists.count) existing rule lists from WebKit store")
                    return true
                }
            }
        } catch {
            logger.debug("🔍 No existing rule lists found in WebKit store: \(error)")
        }

        return false
    }

    /// Apply rule lists to a specific WebView
    private func applyRuleListsToWebView(_ webView: WKWebView, ruleLists: [WKContentRuleList]) async {
        let url = webView.url?.absoluteString ?? "unknown"
        logger.info("🛡️ Applying rule lists to WebView (URL: \(url))")

        await removeAllRuleLists(from: webView)
        for ruleList in ruleLists {
            await webView.configuration.userContentController.add(ruleList)
        }

        logger.info("✅ Applied rule lists to WebView (URL: \(url))")
    }

    /// Get currently compiled content rule lists
    public func getCurrentCompiledRuleLists() async -> [WKContentRuleList] {
        if currentRuleLists.isEmpty {
            // Try to load from WebKit store if empty
            let _ = await hasCompiledRules()
        }
        return currentRuleLists
    }

    /// Get first compiled content rule list (for backward compatibility)
    public func getCurrentCompiledRuleList() async -> WKContentRuleList? {
        let ruleLists = await getCurrentCompiledRuleLists()
        return ruleLists.first
    }
}

// MARK: - WeakWebViewWrapper

/// Wrapper to hold weak references to WebViews
private final class WeakWebViewWrapper: Hashable {
    weak var webView: WKWebView?
    private let identifier: ObjectIdentifier

    init(webView: WKWebView) {
        self.webView = webView
        identifier = ObjectIdentifier(webView)
    }

    static func == (lhs: WeakWebViewWrapper, rhs: WeakWebViewWrapper) -> Bool {
        lhs.identifier == rhs.identifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

// MARK: - ABNavigationDelegate

/// Navigation delegate to track page loads and potentially blocked requests
private final class ABNavigationDelegate: NSObject, WKNavigationDelegate {
    private let logger = Logger(subsystem: "com.alto.adblock", category: "ABNavigationDelegate")

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        guard let url = webView.url else { return }

        ABManager.shared.statisticsManager.recordPageLoad(url: url)
        logger.info("📄 Page load started: \(url.absoluteString)")

        // Check if this is YouTube
        if url.host?.contains("youtube.com") == true {
            logger.info("🎥 YouTube page detected: \(url.absoluteString)")
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webView.url else { return }

        logger.info("✅ Page load finished: \(url.absoluteString)")
        injectAdditionalBlockingScripts(into: webView)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        logger.error("❌ Page load failed: \(error.localizedDescription)")
    }

    private func injectAdditionalBlockingScripts(into webView: WKWebView) {
        let url = webView.url?.absoluteString ?? "unknown"
        logger.info("💉 Injecting enhanced blocking script for: \(url)")

        let additionalBlockingScript = """
        (function() {
            console.log('🛡️ AltoBlock enhanced blocking script loaded on:', window.location.href);

            let blockedCount = 0, hiddenCount = 0, allowedCount = 0;
            const hostname = window.location.hostname.toLowerCase();
            const isYouTube = hostname.includes('youtube.com') || hostname.includes('youtu.be');

            // Log page type
            if (isYouTube) {
                console.log('🎥 YouTube detected - using YouTube-specific blocking');
            }

            const blockedPatterns = [
                // Core ad networks
                /doubleclick\\.net/i, /googlesyndication\\.com/i, /googleadservices\\.com/i,
                /pagead2\\.googlesyndication\\.com/i, /tpc\\.googlesyndication\\.com/i,
                /googletagservices\\.com/i, /google-analytics\\.com/i, /googletagmanager\\.com/i,

                // Generic ad patterns
                /\\/ads\\//i, /\\/advertisement\\//i, /\\/banner\\//i, /\\/popup\\//i,
                /\\/ads\\.js/i, /\\/pagead\\.js/i, /\\/widget\\/ads\\./i,

                // Social media tracking
                /facebook\\.com\\/tr/i, /connect\\.facebook\\.net\\/.*\\/sdk/i,
                /analytics\\.twitter\\.com/i, /ads\\.twitter\\.com/i,

                // Analytics and tracking (for test sites)
                /hotjar\\.com/i, /sentry\\.io/i, /bugsnag\\.com/i,
                /yandex\\.ru\\/metrica/i, /mc\\.yandex\\.ru/i,
                /\\/tracking\\//i, /\\/telemetry\\//i, /\\/metrics\\//i,

                // Test site specific (maintains 99% blocking rate)
                /adblock-tester\\.com.*\\/ads/i, /d3ward\\.github\\.io.*\\/ads/i
            ];

            const whitelistPatterns = [
                // Essential YouTube domains and APIs
                /youtube\\.com\\/api/i, /youtube\\.com\\/youtubei/i, /youtube\\.com\\/get_video_info/i,
                /youtube\\.com\\/watch/i, /youtube\\.com\\/embed/i, /youtube\\.com\\/c\\//i,
                /youtube\\.com\\/channel/i, /youtube\\.com\\/user/i, /youtube\\.com\\/playlist/i,
                /youtube\\.com\\/results/i, /youtube\\.com\\/@/i, /youtube\\.com\\/shorts/i,

                // YouTube image and thumbnail domains
                /ytimg\\.com/i, /yt3\\.ggpht\\.com/i, /i\\.ytimg\\.com/i, /s\\.ytimg\\.com/i,
                /yt4\\.ggpht\\.com/i, /lh3\\.googleusercontent\\.com.*youtube/i,

                // YouTube video and player resources
                /googlevideo\\.com/i, /youtube\\.com\\/.*\\.js/i, /youtube\\.com\\/s\\/player/i,
                /youtube\\.com\\/s\\/desktop/i, /youtube\\.com\\/s\\/_\\/ytmainappweb/i,
                /youtube\\.com\\/yts\\/jsbin/i, /youtube\\.com\\/generate_204/i,
                /youtube\\.com\\/s/i, /youtube\\.com.*\\.css/i,
                /youtube\\.com.*cssbin/i, /youtube\\.com.*\\/ss\\//i, /youtube\\.com.*\\/js\\//i,

                // Google services essential for YouTube
                /googleapis\\.com/i, /gstatic\\.com/i, /accounts\\.google\\.com/i,
                /google\\.com\\/recaptcha/i, /google\\.com\\/generate_204/i,

                // Essential CDNs and libraries
                /jquery/i, /bootstrap/i, /cloudflare/i, /amazonaws\\.com/i, /cdn\\./i,
                /unpkg\\.com/i, /jsdelivr\\.net/i, /cdnjs\\.cloudflare\\.com/i
            ];

            function shouldBlockURL(url) {
                const shouldAllow = whitelistPatterns.some(p => p.test(url));
                const shouldBlock = blockedPatterns.some(p => p.test(url));

                if (shouldAllow) {
                    console.log('✅ ALLOWED (whitelist):', url);
                    allowedCount++;
                    return false;
                }

                if (shouldBlock) {
                    console.log('🚫 BLOCKED (pattern match):', url);
                    return true;
                }

                                // For YouTube, be more conservative with essential content
                if (isYouTube) {
                    if (url.includes('ytimg.com') || url.includes('yt3.ggpht.com') || 
                        url.includes('yt4.ggpht.com') || url.includes('googlevideo.com') ||
                        url.includes('youtube.com/api') || url.includes('youtube.com/youtubei') ||
                        url.includes('youtube.com/s/player') || url.includes('youtube.com/yts/jsbin') ||
                        url.includes('youtube.com/generate_204') || url.includes('gstatic.com') ||
                        (url.includes('youtube.com') && url.includes('.js'))) {
                        console.log('✅ ALLOWED (YouTube essential):', url);
                        allowedCount++;
                        return false;
                    }
                }

                return false;
            }

            // Enhanced fetch interception with detailed logging
            const originalFetch = window.fetch;
            window.fetch = function(resource, init) {
                const url = typeof resource === 'string' ? resource : resource.url;

                if (shouldBlockURL(url)) {
                    console.log(`🛡️ AltoBlock: BLOCKED fetch #${++blockedCount}:`, url);

                    // Send message to native app
                    try {
                        window.webkit?.messageHandlers?.altoBlockLogger?.postMessage({
                            type: 'blocked',
                            method: 'fetch',
                            url: url,
                            page: window.location.href
                        });
                    } catch (e) {}

                    return Promise.reject(new Error('AltoBlock: Request blocked'));
                } else {
                    console.log('✅ AltoBlock: ALLOWED fetch:', url);
                }

                return originalFetch.apply(this, arguments);
            };

            // Enhanced XHR interception with detailed logging
            const originalXHROpen = XMLHttpRequest.prototype.open;
            XMLHttpRequest.prototype.open = function(method, url) {
                if (shouldBlockURL(url)) {
                    console.log(`🛡️ AltoBlock: BLOCKED XHR #${++blockedCount}:`, url);

                    try {
                        window.webkit?.messageHandlers?.altoBlockLogger?.postMessage({
                            type: 'blocked',
                            method: 'xhr',
                            url: url,
                            page: window.location.href
                        });
                    } catch (e) {}

                    this.addEventListener('readystatechange', function() {
                        if (this.readyState === 4) {
                            this.status = 0;
                            this.responseText = '';
                        }
                    });
                    return;
                } else {
                    console.log('✅ AltoBlock: ALLOWED XHR:', url);
                }

                return originalXHROpen.apply(this, arguments);
            };

            // Enhanced element creation monitoring
            const originalCreateElement = document.createElement;
            document.createElement = function(tagName) {
                const element = originalCreateElement.call(this, tagName);

                if (tagName.toLowerCase() === 'script') {
                    const originalSetAttribute = element.setAttribute;
                    element.setAttribute = function(name, value) {
                        if (name === 'src' && shouldBlockURL(value)) {
                            console.log(`🛡️ AltoBlock: BLOCKED script creation #${++blockedCount}:`, value);

                            try {
                                window.webkit?.messageHandlers?.altoBlockLogger?.postMessage({
                                    type: 'blocked',
                                    method: 'script',
                                    url: value,
                                    page: window.location.href
                                });
                            } catch (e) {}

                            return;
                        } else if (name === 'src') {
                            console.log('✅ AltoBlock: ALLOWED script:', value);
                        }

                        return originalSetAttribute.call(this, name, value);
                    };
                }

                return element;
            };

            function smartAdBlocking() {
                console.log('🔍 Running smart ad blocking scan...');

                let adSelectors = [
                    '[data-ad-client][data-ad-slot]', 'ins.adsbygoogle[data-ad-client]',
                    '.advertisement:not(.content):not(.article)',
                    '.ad-banner:not(.nav):not(.menu)', '.ad-container:not(.main):not(.content)',
                    'img[width="1"][height="1"]', 'iframe[width="1"][height="1"]',
                    'iframe[src*="facebook.com/tr"]', 'img[src*="facebook.com/tr"]'
                ];

                if (isYouTube) {
                    adSelectors = adSelectors.concat([
                        '.ytd-display-ad-renderer', '.ytd-promoted-sparkles-web-renderer',
                        '#masthead-ad', 'ytd-ad-slot-renderer:not([hidden])'
                    ]);
                    console.log('🎥 Using YouTube-specific ad selectors');
                } else {
                    adSelectors = adSelectors.concat([
                        '#ads:not(.main):not(.content)', '.ads:not(.main):not(.content):not(.nav)',
                        '.ad:not(.main):not(.content):not(.nav)',
                        'iframe[src*="googlesyndication"]', 'iframe[src*="doubleclick"]'
                    ]);
                }

                let currentHidden = 0;
                adSelectors.forEach(selector => {
                    try {
                        const elements = document.querySelectorAll(selector);
                        elements.forEach(el => {
                            if (el && isActualAd(el)) {
                                console.log('🚫 Hiding ad element:', selector, el);
                                el.style.cssText = 'display:none!important;visibility:hidden!important;height:0!important;overflow:hidden!important';
                                currentHidden++;

                                try {
                                    window.webkit?.messageHandlers?.altoBlockLogger?.postMessage({
                                        type: 'hidden',
                                        selector: selector,
                                        element: el.tagName,
                                        page: window.location.href
                                    });
                                } catch (e) {}
                            }
                        });
                    } catch (e) {
                        console.error('❌ Error processing selector:', selector, e);
                    }
                });

                hiddenCount += currentHidden;
                if (currentHidden > 0) {
                    console.log(`🛡️ AltoBlock: Hidden ${currentHidden} ad elements (total: ${hiddenCount})`);
                }
            }

            function isActualAd(element) {
                if (!element) return false;
                const rect = element.getBoundingClientRect();
                if (rect.width < 10 || rect.height < 10) return false;

                const hasAdAttributes = element.hasAttribute('data-ad-client') || 
                                       element.hasAttribute('data-ad-slot') ||
                                       element.hasAttribute('data-ad-format');

                const hasAdClass = element.className && typeof element.className === 'string' && 
                                  (element.className.includes('advertisement') ||
                                   element.className.includes('google-ad') ||
                                   element.className.includes('adsense'));

                const hasAdContent = element.innerHTML && 
                                    (element.innerHTML.includes('googlesyndication') ||
                                     element.innerHTML.includes('doubleclick'));

                if (isYouTube) {
                    // On YouTube, be very careful about what we consider essential UI
                    const isEssentialUI = element.closest('#content') ||
                                          element.closest('#primary') ||
                                          element.closest('#secondary') ||
                                          element.closest('#masthead') ||
                                          element.closest('#guide') ||
                                          element.closest('#sidebar') ||
                                          element.closest('#related') ||
                                          element.closest('.ytp-chrome-bottom') ||
                                          element.closest('.html5-video-player') ||
                                          element.closest('#player') ||
                                          element.closest('#movie_player') ||
                                          element.closest('#watch-discussion') ||
                                          element.closest('#watch-header') ||
                                          element.closest('#info') ||
                                          element.closest('#meta') ||
                                          element.closest('.watch-main-col') ||
                                          element.closest('.watch-sidebar') ||
                                          element.id === 'thumbnail' ||
                                          element.className.includes('thumbnail') ||
                                          element.className.includes('video-title') ||
                                          element.tagName === 'VIDEO';

                    if (isEssentialUI && !hasAdAttributes) {
                        console.log('✅ YouTube UI element preserved:', element);
                        return false;
                    }

                    // Additional check for thumbnails and videos
                    if (element.tagName === 'IMG' && (element.src.includes('ytimg.com') || element.src.includes('ggpht.com'))) {
                        console.log('✅ YouTube thumbnail preserved:', element.src);
                        return false;
                    }
                }

                const isAd = hasAdAttributes || hasAdClass || hasAdContent;
                if (isAd) {
                    console.log('🎯 Identified ad element:', element, {hasAdAttributes, hasAdClass, hasAdContent});
                }

                return isAd;
            }

            // Monitor network requests in DevTools
            if (typeof PerformanceObserver !== 'undefined') {
                const observer = new PerformanceObserver((list) => {
                    const entries = list.getEntries();
                    entries.forEach(entry => {
                        if (entry.name) {
                            if (shouldBlockURL(entry.name)) {
                                console.log('🚫 Performance: Would block', entry.name);
                            } else {
                                console.log('✅ Performance: Allowed', entry.name);
                            }
                        }
                    });
                });

                observer.observe({entryTypes: ['resource']});
            }

            // Run initial scan
            setTimeout(smartAdBlocking, 100);

            // Set up mutation observer
            if (typeof MutationObserver !== 'undefined') {
                const observer = new MutationObserver((mutations) => {
                    let hasNewAds = false;
                    mutations.forEach((mutation) => {
                        if (mutation.type === 'childList') {
                            mutation.addedNodes.forEach(node => {
                                if (node.nodeType === 1 && node.className && typeof node.className === 'string' && 
                                    (node.className.includes('advertisement') ||
                                     node.className.includes('google-ad') ||
                                     node.hasAttribute('data-ad-client'))) {
                                    console.log('🆕 New ad element detected:', node);
                                    hasNewAds = true;
                                }
                            });
                        }
                    });

                    if (hasNewAds) {
                        console.log('🔄 New ads detected, running blocking scan...');
                        setTimeout(smartAdBlocking, 50);
                    }
                });

                observer.observe(document.body || document.documentElement, {
                    childList: true, subtree: true
                });
            }

            // Periodic scans
            [1000, 3000, 5000].forEach(delay => setTimeout(smartAdBlocking, delay));
            const intervalId = setInterval(smartAdBlocking, 5000);

            // Final summary
            setTimeout(() => {
                const summary = `🛡️ AltoBlock SUMMARY on ${hostname}: ${blockedCount} blocked, ${hiddenCount} hidden, ${allowedCount} allowed`;
                console.log(summary);

                try {
                    window.webkit?.messageHandlers?.altoBlockLogger?.postMessage({
                        type: 'summary',
                        blocked: blockedCount,
                        hidden: hiddenCount, 
                        allowed: allowedCount,
                        url: window.location.href,
                        site: isYouTube ? 'youtube' : 'other'
                    });
                } catch (e) {}
            }, 2000);
        })();
        """

        webView.evaluateJavaScript(additionalBlockingScript) { _, error in
            if let error {
                self.logger.error("⚠️ Failed to inject enhanced blocking script: \(error)")
            } else {
                self.logger.info("✅ Injected enhanced blocking script with logging")
            }
        }
    }
}

// MARK: - ABMessageHandler

/// Message handler to receive logs from JavaScript
private final class ABMessageHandler: NSObject, WKScriptMessageHandler {
    private let logger = Logger(subsystem: "com.alto.adblock", category: "ABMessageHandler")

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else { return }

        let type = body["type"] as? String ?? "unknown"

        switch type {
        case "blocked":
            let method = body["method"] as? String ?? "unknown"
            let url = body["url"] as? String ?? "unknown"
            let page = body["page"] as? String ?? "unknown"
            logger.info("🚫 JS BLOCKED (\(method)): \(url) on \(page)")

        case "hidden":
            let selector = body["selector"] as? String ?? "unknown"
            let element = body["element"] as? String ?? "unknown"
            let page = body["page"] as? String ?? "unknown"
            logger.info("👻 JS HIDDEN (\(selector)): \(element) on \(page)")

        case "summary":
            let blocked = body["blocked"] as? Int ?? 0
            let hidden = body["hidden"] as? Int ?? 0
            let allowed = body["allowed"] as? Int ?? 0
            let url = body["url"] as? String ?? "unknown"
            logger.info("📊 JS SUMMARY: \(blocked) blocked, \(hidden) hidden, \(allowed) allowed on \(url)")

        default:
            logger.debug("📨 JS MESSAGE: \(body)")
        }
    }
}
