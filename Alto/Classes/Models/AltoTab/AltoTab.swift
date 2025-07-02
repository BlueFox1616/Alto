//
//  AltoTab.swift
//  OpenADK
//
//  Created by StudioMovieGirl
//

import AppKit
import SwiftUI
import WebKit

// MARK: - ADKTab

/// A Genaric Tab class that can be subclassed for more specific browser use cases
@Observable
open class ADKTab: NSObject, Identifiable, ADKTabProtocol {
    public let id = UUID()

    public var tabRepresentation: TabRepresentation?

    public var location: TabLocation?

    public var content: [any Displayable] = []

    public var activeContent: Displayable?

    public var state: AltoState

    public var manager: TabManager? {
        state.tabManager
    }

    public var isCurrentTab: Bool {
        manager?.currentTab?.id == id
    }

    public init(state: AltoState) {
        self.state = state
    }

    public func setContent(content addedContent: any Displayable) {
        if !content.isEmpty {
            content[0] = addedContent
            activeContent = addedContent
        } else {
            activeContent = addedContent
            content.append(addedContent)
        }
    }

    public func createNewTab(_: String, _: WKWebViewConfiguration, frame _: CGRect = .zero) {}

    public func closeTab() {
        location?.removeTab(id: id)
        state.tabManager.removeTab(id)
        activeContent = nil
        for c in content {
            c.removeWebView()
        }

        if isCurrentTab {
            manager?.currentTab = nil
        }
    }
}

// MARK: - ADKTabProtocol

public protocol ADKTabProtocol: AnyObject, Identifiable {
    var id: UUID { get }
    var tabRepresentation: TabRepresentation? { get set }
    var location: TabLocation? { get set }
    var content: [any Displayable] { get set }
    var activeContent: Displayable? { get set }
    var state: AltoState { get }
    var manager: TabManager? { get }
    var isCurrentTab: Bool { get }

    func setContent(content: any Displayable)
    func createNewTab(_ url: String, _ config: WKWebViewConfiguration, frame: CGRect)
    func closeTab()
}
