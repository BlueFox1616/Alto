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
public class ADKTab: NSObject, Identifiable {
     public let id = UUID()

     var tabRepresentation: TabRepresentation?

     var location: TabLocation?

     var content: [any Displayable] = []

     var activeContent: Displayable?

    var state: AltoState? {
        return WindowManager.shared.window?.state
    }

     var manager: TabManager? {
        state?.tabManager
    }

     var isCurrentTab: Bool {
        manager?.currentTab?.id == id
    }

     override init() {
    }

     func setContent(content addedContent: any Displayable) {
        if !content.isEmpty {
            content[0] = addedContent
            activeContent = addedContent
        } else {
            activeContent = addedContent
            content.append(addedContent)
        }
    }

     func createNewTab(_: String, _: WKWebViewConfiguration, frame _: CGRect = .zero) {}

     func closeTab() {
         print("called close tab on:", self.content[0].title )
        location?.removeTab(id: id)
        state?.tabManager.removeTab(id)
        activeContent = nil
        for c in content {
            c.removeWebView()
        }

        if isCurrentTab {
            manager?.currentTab = nil
        }
    }
}
