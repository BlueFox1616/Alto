//
//  ADKWebPage.swift
//  OpenADK
//
//  Created by StudioMovieGirl
//

import SwiftUI

import UniformTypeIdentifiers
import WebKit

// MARK: - Displayable

/// A Protocol for what can be displayed as tab content
public protocol Displayable {
    var parent: ADKTab? { get set }
    
    var id: UUID { get }
    var title: String { get set }
    var favicon: NSImage? { get set }
    
    var canGoBack: Bool { get set }
    var canGoForward: Bool { get set }
    var isLoading: Bool { get set }
    
    func createNewTab(_ url: String, _ configuration: WKWebViewConfiguration, frame: CGRect)
    func goBack()
    func goForward()
    
    func removeWebView()
    
}

// MARK: - ADKWebPage

/// A simple webpage that conforms to the Tab Displayable protocol

///
/// WebPage represents a single web page within a browser tab, handling navigation,
/// downloads, and web view lifecycle management. It acts as the bridge between
/// the browser's tab system and the underlying WKWebView.
@Observable
public class ADKWebPage: NSObject, Identifiable, Displayable {
    
    /// Reference to the parent tab containing this web page
    public var parent: ADKTab?
    
    /// Unique identifier for this web page instance
    public let id = UUID()
    
    /// The title of the web page, automatically updates the window title when changed
    public var title = "Untitled" // {
        // didSet { state.window?.title = title }
    //}
    
    /// The underlying web view instance
    public var webView: ADKWebView
    
    /// The favicon image for this web page
    public var favicon: NSImage?
    
    /// The NSView representation of the web view
    public var view: NSView { webView }
    
    /// Whether the web view can navigate back
    public var canGoBack = false
    
    /// Whether the web view can navigate forward
    public var canGoForward = false
    
    /// Whether the web page is currently loading
    public var isLoading = false
    
    /// UI delegate for handling web view UI events
    public var uiDelegate: WKUIDelegate?
    
    /// Download delegate for handling download events
    public var downloadDelegate: WKDownloadDelegate?
    
    /// Navigation delegate for handling navigation events
    public var navigationDelegate: WKNavigationDelegate?
    
    public var isInActiveWindow: Bool {
        if WindowManager.shared.window?.state.currentContent?[0].id == self.id {
            return true
        } else {
            return false
        }
    }
    /// Initializes a new WebPage instance
    /// - Parameters:
    ///   - webView: The AltoWebView instance to wrap
    ///   - state: The application state manager
    ///   - parent: Optional parent tab reference
    public init(webView: ADKWebView, state: AltoState, parent: ADKTab? = nil) {
        self.webView = webView
        super.init()
        
        state.setup(webView: webView)
        webView.ownerTab = self
        webView.uiDelegate = self
        webView.navigationDelegate = self
    }
    
    /// Creates a new tab with the specified URL and configuration
    /// - Parameters:
    ///   - url: The URL to load in the new tab
    ///   - configuration: The web view configuration to use
    ///   - frame: The frame for the new web view
    public func createNewTab(_: String, _: WKWebViewConfiguration, frame _: CGRect) {}
    
    /// Handles mouse down events to activate this tab
    public func handleMouseDown() {
        guard parent?.activeContent?.id != id else { return }
        parent?.activeContent = self
    }
    
    /// Navigates the web view back in history
    public func goBack() { webView.goBack() }
    
    /// Navigates the web view forward in history
    public func goForward() { webView.goForward() }
    
    /// Removes and cleans up the web view
    
    public func removeWebView() {
        webView.stopLoading()
        webView.delegate = nil
        webView.navigationDelegate = nil
    }
    
    /// Returns the SwiftUI view representation of this web page
    /// - Returns: A SwiftUI view containing the web view or a Spacer if unavailable
    public func returnView(_ isActive: Bool) -> any View {
                
        let views = WindowManager.shared.windows.filter { $0.state.currentContent?[0].id == self.id }
        
        if views.count > 1 && !isActive {
            let viewToCapture = webView
            let rep = viewToCapture.bitmapImageRepForCachingDisplay(in: viewToCapture.bounds)!
            viewToCapture.cacheDisplay(in: viewToCapture.bounds, to: rep)
            
            let img = NSImage(size: viewToCapture.bounds.size)
            img.addRepresentation(rep)
            
            let view = GeometryReader { geometry in
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .background {
                        Rectangle().fill(.black)
                    }
                    .blur(radius: 10)
                    .overlay {
                        
                        VStack {
                            Image(systemName: "eye.slash")
                                .font(.system(size: 50))
                                .frame(width: 70, height: 70)
                            Text("This page is activly open in a diferent window")
                                .font(.system(size: 20))
                        }
                    }
            }
            return view
        }
        return WebViewContainer(webView: webView)
    }
}

// MARK: WKNavigationDelegate, WKUIDelegate

extension ADKWebPage: WKNavigationDelegate, WKUIDelegate {
    /// Called when the web view finishes loading a page
    /// - Parameters:
    ///   - webView: The web view that finished loading
    ///   - navigation: The navigation object
    public func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        title = webView.title ?? "test"
        
        
        let js = """
            (function() {
                var bg = window.getComputedStyle(document.body, null).getPropertyValue('background-color');
            
                return bg;
            })();
            """
        
        webView.evaluateJavaScript(js) { result, error in
            if let color = result as? String {
                print(color)
                self.webView.backgroundColor = Color(cssRGBString: color)?.cgColor ?? CGColor.white
            } else {
                print("nothin")
            }
        }

        
        if let url = webView.url {
            FaviconManager.shared.fetchFaviconFromHTML(webView: webView, baseURL: url) { [weak self] image in
                DispatchQueue.main.async { self?.favicon = image }
            }
        }
        
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }
    
    /// Called when the web view is closed
    /// - Parameter webView: The web view that was closed
    public func webViewDidClose(_: WKWebView) {
        parent?.closeTab()
    }
    
    /// Creates a new web view for handling new window requests
    /// - Parameters:
    ///   - webView: The web view requesting the new window
    ///   - configuration: The configuration for the new web view
    ///   - navigationAction: The navigation action that triggered the request
    ///   - windowFeatures: The window features for the new window
    /// - Returns: A new web view instance or nil if the request should be ignored
    public func webView(
        _: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures _: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        
        let newWebView = ADKWebView(frame: .zero, configuration: configuration)
        
        if navigationAction.navigationType != .other,
           let url = navigationAction.request.url {
            newWebView.load(URLRequest(url: url))
        }
        
        return createNewTab(with: newWebView)
    }
    
    /// Creates a new tab with the provided web view
    /// - Parameter webView: The web view to use for the new tab
    /// - Returns: The created web view instance
    private func createNewTab(with webView: ADKWebView) -> WKWebView? {
        
        guard let currentWindow = WindowManager.shared.window else {
            return nil
        }
        
        let state = currentWindow.state
        
        let newWebPage = ADKWebPage(webView: webView, state: state)
        let newTab = ADKTab()
        newTab.location = parent?.location
        newTab.setContent(content: newWebPage)
        newWebPage.parent = newTab
        
        let newTabIndex = parent?.tabRepresentation?.index ?? 0
        let tabRep = TabRepresentation(id: newTab.id, index: newTabIndex)
        newTab.tabRepresentation = tabRep
        
        state.tabManager.addTab(newTab)
        parent?.location?.addTab(tabRep)
        
        CookiesManager.shared.setupCookies(for: webView)
        state.tabManager.setActiveTab(newTab)
        
        return webView
    }
    
    // Preforms a download if the user navagates to a page that initiates a download
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        if navigationAction.shouldPerformDownload {
            print("should preform download")
            decisionHandler(.download, preferences)
        } else {
            decisionHandler(.allow, preferences)
        }
    }
    
    // if the user navagates to a page where the content is not displayable it downloads the content instead
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if navigationResponse.canShowMIMEType {
            decisionHandler(.allow)
        } else {
            print("should preform download 2")
            decisionHandler(.download)
        }
    }
    
    // Asignes the webpage as the delagete for what just got downloaded
    public func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = DownloadManager.shared.self
    }
    
    // Asignes the webpage as the delagete for what just got downloaded
    public func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = DownloadManager.shared.self
    }
}
