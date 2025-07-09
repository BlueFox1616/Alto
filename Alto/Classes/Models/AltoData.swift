//
//  AltoData.swift
//  OpenADK
//
//  Created by StudioMovieGirl
//

import Observation
import SwiftUI

// MARK: - Alto

/// Alto is a singleton that allows for global app data such as tab instances or spaces
@Observable
public class AltoData {
    // MARK: - Properties

    public static let shared = AltoData()

    // Global shared data across browser windows
    public var tabs: [UUID: ADKTab] = [:]
    public var spaces: [Space] = []

    private var profiles: [Profile] {
        ProfileManager.shared.profiles
    }

    // Managers
    var spaceManager: SpaceManager

    // MARK: - Initialization

    private init() {
        spaceManager = SpaceManager()

        
        let defaultProfile = ProfileManager.shared.defaultProfile
        
        // Temporary decleration of spaces
        spaces = [
            Space(profile: defaultProfile, name: "Latent Space"),
            Space(profile: defaultProfile, name: "The Final Frontier")
        ]
    }

    public func getTab(id: UUID) -> ADKTab? {
        guard let tab = tabs.first(where: { $0.key == id })?.value else {
            return nil
        }
        return tab
    }
}
