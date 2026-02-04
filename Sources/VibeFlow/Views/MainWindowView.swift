import SwiftUI

/// Navigation sections for the main window
enum NavigationSection: String, CaseIterable, Identifiable {
    case home = "Home"
    case languages = "Idiomas"
    case modes = "Modos"
    case snippets = "Snippets"
    case style = "Estilo"
    case settings = "Ajustes"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house"
        case .languages: return "globe"
        case .modes: return "waveform"
        case .snippets: return "text.badge.plus"
        case .style: return "textformat"
        case .settings: return "gearshape"
        }
    }

    var iconFilled: String {
        switch self {
        case .home: return "house.fill"
        case .languages: return "globe.americas.fill"
        case .modes: return "waveform"
        case .snippets: return "text.badge.plus"
        case .style: return "textformat"
        case .settings: return "gearshape.fill"
        }
    }
}

/// Main window with sidebar navigation - inspired by modern macOS apps
struct MainWindowView: View {
    @State private var selectedSection: NavigationSection = .home
    @StateObject private var settings = SettingsManager.shared

    var body: some View {
        NavigationSplitView {
            // MARK: - Sidebar
            VStack(alignment: .leading, spacing: 0) {
                // Logo/Brand
                HStack(spacing: 8) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.purple)

                    Text("VibeFlow")
                        .font(.system(size: 18, weight: .semibold))

                    Text("2.1")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)

                // Navigation Items
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(NavigationSection.allCases) { section in
                        SidebarItem(
                            section: section,
                            isSelected: selectedSection == section
                        ) {
                            selectedSection = section
                        }
                    }
                }
                .padding(.horizontal, 12)

                Spacer()

                // Footer
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.horizontal, 16)

                    // Quick Stats
                    if AnalyticsManager.shared.totalTranscriptions > 0 {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(AnalyticsManager.shared.totalTranscriptions)")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("transcricoes")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(formatTime(AnalyticsManager.shared.totalRecordingTime))
                                    .font(.system(size: 14, weight: .semibold))
                                Text("gravado")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }

                    // Version
                    Text("Versao 2.1.0")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
            }
            .frame(minWidth: 200, maxWidth: 220)
            .background(Color(nsColor: .controlBackgroundColor))
        } detail: {
            // MARK: - Content Area
            Group {
                switch selectedSection {
                case .home:
                    HomeView()
                case .languages:
                    LanguagesView()
                case .modes:
                    ModesView()
                case .snippets:
                    SnippetsView()
                case .style:
                    StyleView()
                case .settings:
                    SettingsDetailView()
                }
            }
            .frame(minWidth: 500)
        }
        .frame(minWidth: 720, minHeight: 520)
    }

    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            return "\(hours)h"
        }
    }
}

/// Sidebar navigation item
struct SidebarItem: View {
    let section: NavigationSection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? section.iconFilled : section.icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                    .foregroundStyle(isSelected ? .purple : .secondary)

                Text(section.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.purple.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainWindowView()
}
