//
//  ADKWebView.swift
//  Alto
//
//  Created by StudioMovieGirl
//

import AppKit
import WebKit
import SwiftUI
// MARK: - ADKWebView

/// Custom verson of WKWebView to avoid needing an extra class for management
@Observable
public class ADKWebView: WKWebView, webViewProtocol {
    public var ownerTab: ADKWebPage?
    public var currentConfiguration: WKWebViewConfiguration
    public var delegate: WKUIDelegate?
    public var navDelegate: WKNavigationDelegate?
    
    private let backgroundView = NSView()
    private let backingView = NSView()
    
    public var backgroundColor: CGColor = NSColor.white.cgColor  {
        didSet {
            backgroundView.layer?.backgroundColor = backgroundColor
        }
    }
    
    private let backingColor = NSColor.windowBackgroundColor.cgColor
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        currentConfiguration = configuration
        
        
        super.init(frame: frame, configuration: configuration)
        setupView()
        
        allowsMagnification = true
        customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        
        // Notify that a new WebView was created so AdBlock can be set up
        NotificationCenter.default.post(
            name: NSNotification.Name("AltoWebViewCreated"),
            object: self
        )
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
    
    deinit {}
    
    private func setupView() {
        
        // Creates the page background view set to the pages background color
        backgroundView.wantsLayer = true
        backgroundView.layer?.backgroundColor = backgroundColor
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView, positioned: .below, relativeTo: nil)
        
        // Creates a backing view set to white to handle transparent pages
        backingView.wantsLayer = true
        backingView.layer?.backgroundColor = backingColor
        backingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backingView, positioned: .below, relativeTo: nil)
        
        
        NSLayoutConstraint.activate([
            backingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backingView.topAnchor.constraint(equalTo: topAnchor),
            backingView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    public override func mouseDown(with theEvent: NSEvent) {
        super.mouseDown(with: theEvent)
        ownerTab?.handleMouseDown()
    }
    
    public override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        super.willOpenMenu(menu, with: event)
        
        let items = menu.items
        
        var object = "nil"
        
        // For all default menu items which open a new Window, we add custom menu items
        // to open the object in a new Tab and to add them to the bookmarks.
        for idx in (0..<items.count).reversed() {
            if let id = items[idx].identifier?.rawValue {
                
                if id == "WKMenuItemIdentifierOpenLinkInNewWindow" {
                    object = "Link"
                    break
                } else if id == "WKMenuItemIdentifierOpenImageInNewWindow" {
                    object = "Image"
                    break
                } else if id == "WKMenuItemIdentifierOpenMediaInNewWindow" {
                    object = "Video"
                    break
                } else if id == "WKMenuItemIdentifierLookUp" {
                    object = "Text"
                    break
                } else if id == "WKMenuItemIdentifierPaste" {
                    object = "Editable"
                    break
                } else {
                    object = "Frame"
                }
            }
        }
        
        if object == "image" {
            let tabMenuItem = NSMenuItem(title:"copy Image", action: #selector(downloadImage(_:)), keyEquivalent:"")
            tabMenuItem.identifier = NSUserInterfaceItemIdentifier("TITLE")
            tabMenuItem.target = self
            // tabMenuItem.representedObject = items[idx]
            menu.items.append(tabMenuItem)
        }
    }
    
    @objc func downloadImage(_ sender: NSMenuItem) {
        print("Hit Download")
    }
    
    public func updateColor(color: NSColor) {
        print("updated!")
        
    }
}

// MARK: - webViewProtocol

public protocol webViewProtocol: WKWebView {
    var currentConfiguration: WKWebViewConfiguration { get set }
    var delegate: WKUIDelegate? { get set }
    var navDelegate: WKNavigationDelegate? { get set }
}

enum ADKContextItems {
    // forward
    // back
    // reload
    
    // seperator
    
    // View Page Source
    // Inspect
    
    // search for X
    // Copy
    // define X
    // Speach
    
    //
}

public protocol WKContextMenuDelegate {
    
}


class ADKContextMenuDelegate {
    
    
    public func addMenuItem(title: String, action: () -> (), index: Int?) {
        
    }
}


