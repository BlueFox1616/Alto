//
//  TabsManager.swift
//  OpenADK
//
//  Created by StudioMovieGirl
//

import AppKit
import Observation
import WebKit

// MARK: - TabsManager

/// Manges Tabs for each Window
///
///  Tabs will be stored in Alto in future in order to support tabs being shared between windows (like Arc)
@Observable
class TabManager {
    public var state: AltoState?
    public var currentTab: ADKTab?
    private var profile: Profile?
    public var currentSpace: Space?

    public init(state: AltoState? = nil, profile: Profile? = nil, tabLocations: [TabLocation]? = nil) {
        self.state = state
        self.profile = profile
    }

    public func setupTabs(tabs: [ADKTab], location: TabLocation? = nil) {
        guard !tabs.isEmpty else {
            return
        }

        for tab in tabs {
            createNewTab(newTab: tab, location: location)
        }

        currentTab = tabs.last
    }

    public func setActiveTab(_ tab: ADKTab) {
        print("ran set active tab")
        currentTab = tab
    }

    public func closeActiveTab() {
        guard let currentTab else {
            return
        }
        currentTab.closeTab()
    }

    open func addTab(_ tab: ADKTab) {
        print("added tab")
        AltoData.shared.tabs[tab.id] = tab
    }

    public func removeTab(_ id: UUID) {
        let tab = AltoData.shared.getTab(id: id)
        tab?.location?.removeTab(id:id)
        AltoData.shared.tabs.removeValue(forKey: id)
    }

    public func createNewTab(
        url: String = "https://www.google.com/",
        frame: CGRect = .zero,
        location: TabLocations
    ) {
        guard let state else {
            return
        }
        
        let tabLocation: TabLocation?
        switch location {
        case .daily:
            tabLocation = currentSpace?.dailyTabs
        case .pinned:
            tabLocation = currentSpace?.pinnedTabs
        case .favorite:
            tabLocation = currentSpace?.profile?.favorites
        }
        guard let tabLocation = tabLocation else {
            print("failed to find tab location")
            return
        }

        let profile = self.currentSpace?.profile ?? ProfileManager.shared.defaultProfile
        let dataStore = WKWebsiteDataStore(forIdentifier: profile.id)
        let configuration = ADKWebViewConfigurationBase(dataStore: dataStore)

        let newWebView = ADKWebView(frame: frame, configuration: configuration)
        
        CookiesManager.shared.setupCookies(for: newWebView)

        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            newWebView.load(request)
        }

        let newTab = ADKTab()

        let newWebPage = ADKWebPage(webView: newWebView, state: state, parent: newTab)
        newWebPage.parent = newTab

        newTab.setContent(content: newWebPage)

        let tabRep = TabRepresentation(id: newTab.id, index: tabLocation.tabs.count)
        newTab.tabRepresentation = tabRep

        addTab(newTab)

        tabLocation.addTab(tabRep)
        setActiveTab(newTab)
    }

     func createNewTab(
        newTab: ADKTab,
        location: TabLocation? = nil
    ) {

        guard let tabLocation = location ?? currentSpace?.dailyTabs else {
            print("failed to find tab location")
            return
        }

        newTab.location = tabLocation

        var tabRep = newTab.tabRepresentation!
        tabRep.index = tabLocation.tabs.count

        newTab.tabRepresentation = tabRep

        addTab(newTab)

        tabLocation.addTab(tabRep)
        setActiveTab(newTab)
    }
}
