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
