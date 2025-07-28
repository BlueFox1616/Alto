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
public class ADKWebView: WKWebView {
    public var ownerTab: ADKWebPage?
    public var currentConfiguration: WKWebViewConfiguration
    public var delegate: WKUIDelegate?
    public var navDelegate: WKNavigationDelegate?
    
    private let backgroundView = NSView()
    private let backingView = NSView()
    
    private let contentControler: WKUserContentController
    private let menuHandler: ContextMenuHandler
    
    public var backgroundColor: CGColor = NSColor.white.cgColor  {
        didSet {
            backgroundView.layer?.backgroundColor = backgroundColor
        }
    }
    
    private let backingColor = NSColor.windowBackgroundColor.cgColor
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        currentConfiguration = configuration
        
        contentControler = configuration.userContentController
        
        menuHandler = ContextMenuHandler()
        
        super.init(frame: frame, configuration: configuration)

        
        guard let jsPath = Bundle.main.path(forResource: "ContextMenuHandler", ofType: "js") else {
            print("Could not find ContextMenuHandler.js")
            return
        }

        do {
            let jsSource = try String(contentsOfFile: jsPath)
            let userScript = WKUserScript(source: jsSource, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            self.configuration.userContentController.addUserScript(userScript)
        } catch {
            print("Failed to load JS: \(error)")
        }
        
        contentControler.add(menuHandler, name: "menuHandler")
        
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
        
        // let items = menu.items
    }
    
    @objc func downloadImage(_ sender: NSMenuItem) {
        print("Hit Download")
    }
    
    public func updateColor(color: NSColor) {
        print("updated!")
        
    }
}

class ContextMenuHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "menuHandler",
              let info = message.body as? [String: Any] else {
            return
        }
        
        print(info)
    }
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
