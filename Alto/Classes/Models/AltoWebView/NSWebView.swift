//
//  NSWebView.swift
//  OpenADK
//
//  Created by StudioMovieGirl
//

import SwiftUI

// MARK: - WebViewContainer

/// Allows the webview to be displayed in swiftUI
/// The content view needs to be wrapped in another container to avoid glitching issues and frame resets due to full
/// screan
public struct WebViewContainer: View, NSViewRepresentable {
    var webView: NSView
    
    public func makeNSView(context: Context) -> NSViewType {
        let containerView = NSView()
                
        webView.frame = containerView.bounds
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")
        
        containerView.addSubview(webView)
        
        return containerView
    }
    
    public func updateNSView(_ nsView: NSView, context: Context) {
        nsView.subviews.forEach { $0.removeFromSuperview() }
        
        webView.setValue(false, forKey: "drawsBackground")
        webView.frame = nsView.bounds
        webView.autoresizingMask = [.width, .height]
        
        
        
        nsView.addSubview(webView)
    }
}
