//
import SwiftUI
import UniformTypeIdentifiers

import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    @Bindable var preferences = PreferencesManager.shared
    @State private var test = true

    var body: some View {
        TabView {
            Tab("General", systemImage: "gearshape") {
                ZStack {
                    VStack(spacing: 0) {
                        SettingsHeader()
                        SettingsRectangle {
                            SettingsCard {
                                SettingsRow(title: "Default browser") {
                                    Button("Set Alto as default browser") {}
                                }
                            }
                            SettingsCard {
                                SettingsRow(title: "Theme") {
                                    Picker("Theme", selection: $preferences.colorScheme) {
                                        ForEach(ColorSchemePreference.allCases) { scheme in
                                            Text(scheme.displayName).tag(scheme)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                                Divider()
                                SettingsRow(title: "Sidebar position") {
                                    Picker("", selection: $preferences.storedSidebarPosition) {
                                        Label("Top (Horizontal)", systemImage: "inset.filled.topthird.square")
                                            .tag("top")
                                        Label("Left Sidebar", systemImage: "sidebar.left").tag("left")
                                        // TODO: Fix the right sidebar's design
                                        // Label("Right Sidebar", systemImage: "sidebar.right").tag("right")
                                    }
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: 200)
                                }
                            }
                            Spacer()
                            HStack {
                                Spacer()
                                Button("Acknowledgements") {}
                            }
                        }
                        .frame(minHeight: 250)
                    }
                }
            }

            Tab("Behaviour", systemImage: "slider.horizontal.3") {}

            Tab("Search", systemImage: "magnifyingglass") {
                SettingsRectangle {
                    SettingsCard(title: "Search") {
                        SettingsRow(title: "Search engine") {
                            Picker("Search Engine", selection: $preferences.searchEngine) {
                                ForEach(SearchManager.popularSearchEngines, id: \.rawValue) { engine in
                                    Label(engine.displayName, systemImage: engine.iconName)
                                        .tag(engine)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: 200)
                        }
                        Divider()
                        SettingsRow(title: "Search Sugggestions") {
                            if SearchManager.shared.supportsSuggestions {
                                Toggle("", isOn: $test)
                                    .toggleStyle(.switch)
                                    .controlSize(.small)
                            } else {
                                Text("Search suggestions not supported")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    SettingsCard {
                        SettingsRow(title: "Clear Search History") {
                            Button("Clear") {}
                        }
                        SettingsRow(title: "") {
                            Text("Recent searches: \(SearchManager.shared.getRecentSearches().count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .frame(width: 650)
        .preferredColorScheme(PreferencesManager.shared.colorScheme.asColorScheme)
    }
}

// MARK: - SettingsRow

struct SettingsRow<Content: View>: View {
    let title: String
    @ViewBuilder let trailing: Content

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            trailing
        }
    }
}

// MARK: - SettingsCard

struct SettingsCard<Content: View>: View {
    var title: String? = ""
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            if let title {
                Text(title)
                    .bold()
                    .font(.system(size: 15))
                    .padding(.leading, 5)
                Spacer()
            }
        }
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .padding(10)
        .background(Color.gray.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.gray, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

// MARK: - SettingsRectangle

struct SettingsRectangle<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack {
            content
        }
        .scenePadding()
    }
}

struct SettingsHeader: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Image("AltoHeader")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: 250)
                .clipped()

            LinearGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color(NSColor.windowBackgroundColor)
                ]),
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 250)
            .frame(maxWidth: .infinity, alignment: .bottom)
        }
        .frame(maxHeight: 250)
    }
}
