//
//  PreferencesManager.swift
//  OpenADK
//
//  Created by StudioMovieGirl
//

import Combine
import Observation
import SwiftUI

// MARK: - PreferencesManager

@Observable
public final class PreferencesManager {
    public static let shared = PreferencesManager()

    
    var colorScheme: ColorSchemePreference = ColorSchemePreference(rawValue: Defaults.retreiveValue(key: .colorScheme, as: String.self) ?? "system")! {
        didSet { Defaults.updateValue(value: colorScheme.rawValue, key: .colorScheme) }
    }

    var searchEngine: SearchEngine = SearchEngine(rawValue: Defaults.retreiveValue(key: .searchEngine, as: String.self) ?? "google")! {
        didSet { Defaults.updateValue(value: searchEngine.rawValue, key: .searchEngine) }
    }

    @UserDefault(key: "sidebarPosition", defaultValue: "top")
    @ObservationIgnored public var storedSidebarPosition: String

    @UserDefault(key: "downloadPath", defaultValue: "")
    @ObservationIgnored public var storedDownloadPath: String

    /// Publicly available and observed version of Preferences
    public var sidebarPosition: SidebarPosition
    public var downloadPath: URL

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Initialize with default values first
        colorScheme = .system
        sidebarPosition = .top
        downloadPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!

        // Then update with actual stored values
        sidebarPosition = Self.getSidebarPosition(from: storedSidebarPosition)
        downloadPath = Self.getDownloadPath(from: storedDownloadPath)
    }

    // Make these static methods so they can be called during initialization
    public static func getScheme(from string: String) -> ColorScheme? {
        switch string {
        case "dark": .dark
        case "light": .light
        default: nil
        }
    }

    public static func getSearchEngine(string: String) -> SearchEngine {
        switch string {
        case "google": .google
        case "duckduckgo": .duckduckgo
        case "brave": .brave
        case "bing": .bing
        case "yahoo": .yahoo
        case "startpage": .startpage
        case "searx": .searx
        case "none": .none
        default: .google
        }
    }

    public static func getSidebarPosition(from string: String) -> SidebarPosition {
        switch string {
        case "left": .left
        case "right": .right
        case "top": .top
        default: .top
        }
    }

    // Method to update sidebar position and persist it
    public func setSidebarPosition(_ position: SidebarPosition) {
        sidebarPosition = position
        storedSidebarPosition = position.rawValue
    }
    
    public static func getDownloadPath(from string: String) -> URL {
        if string.isEmpty {
            // Default to Downloads folder
            return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        } else {
            // Use stored path, with fallback to Downloads if invalid
            let url = URL(fileURLWithPath: string)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            } else {
                return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            }
        }
    }
    
    // Method to update download path and persist it
    public func setDownloadPath(_ path: URL) {
        downloadPath = path
        storedDownloadPath = path.path
    }
}

// MARK: - SidebarPosition

public enum SidebarPosition: String, CaseIterable {
    case top
    case left
    case right
}

