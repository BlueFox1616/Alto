//
//  ADKWindow.swift
//  OpenADK
//
//  Created by StudioMovieGirl
//

import AppKit

// MARK: - AltoWindow

open class AltoWindow: NSWindow {
    public private(set) var id = UUID()
    public var profile: Profile?

    public let state: AltoState

    private var data: AltoData {
        AltoData.shared
    }

    private var hostingView: NSView?
    public var showWinowButtons = false

    public init(
        rootView: NSView? = nil,
        state: AltoState? = nil,
        profile: Profile? = nil,
        useDefaultProfile: Bool = true,
        contentRect: NSRect? = nil
    ) {
        let config = DefaultWindowConfiguration()
        self.state = state ?? AltoState()
        let defaultProfile = ProfileManager.shared.defaultProfile
        self.profile = useDefaultProfile ? defaultProfile : profile

        super.init(
            contentRect: config.contentRect,
            styleMask: config.styleMask,
            backing: .buffered,
            defer: false
        )
        minSize = config.defaultMinimumSize

        /// Window Configurations
        toolbar?.isVisible = false
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isReleasedWhenClosed = false
        isMovableByWindowBackground = false
        isMovable = false

        /// Removes the window buttons
        if !showWinowButtons {
            standardWindowButton(NSWindow.ButtonType.closeButton)?.isHidden = true
            standardWindowButton(NSWindow.ButtonType.zoomButton)?.isHidden = true
            standardWindowButton(NSWindow.ButtonType.miniaturizeButton)?.isHidden = true
        }

        // let defaultView = NSHostingView(rootView: DefaultBrowserView())
        contentView = rootView // ?? defaultView
    }

    func getTitle() -> String {
        state.currentContent?[0].title ?? ""
    }

    func setTitle(_ title: String) {
        self.title = title
    }
}


import Cocoa

class CustomWindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        
        guard let window = self.window else { return }

        // Define the button types you want (close, minimize, zoom)
        let btnTypes: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
        
        // Access the standard traffic light buttons
        let trafficLightButtons: [NSButton] = btnTypes
            .compactMap { window.standardWindowButton($0) }
        
        // Example: Move or customize the buttons
        for (index, button) in trafficLightButtons.enumerated() {
            button.setFrameSize(NSSize(width: 20, height: 20)) // Make them slightly larger
            button.frame.origin.x += CGFloat(index) * 5 // Space them out a little
            button.toolTip = "Custom button \(index)"
        }
    }
}
