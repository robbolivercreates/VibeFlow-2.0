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
                HStack(spacing: 10) {
                    // Custom VoxAiGo logo
                    VoxAiGoLogo(size: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("VoxAiGo")
                            .font(.system(size: 17, weight: .semibold))

                        Text("v2.1")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
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
                    Text("Versao \(AppVersion.current)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
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

/// Custom VoxAiGo logo - Minimalist waveform in a rounded square
struct VoxAiGoLogo: View {
    let size: CGFloat

    // Brand color
    private let brandColor = Color(red: 0.45, green: 0.38, blue: 0.85)

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.42, green: 0.35, blue: 0.85),
                            Color(red: 0.52, green: 0.42, blue: 0.90)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Waveform bars
            HStack(spacing: size * 0.06) {
                ForEach(barHeights.indices, id: \.self) { index in
                    RoundedRectangle(cornerRadius: size * 0.04)
                        .fill(Color.white)
                        .frame(width: size * 0.10, height: size * barHeights[index])
                }
            }
        }
        .frame(width: size, height: size)
    }

    private var barHeights: [CGFloat] {
        [0.22, 0.42, 0.58, 0.48, 0.30]
    }
}

#Preview {
    MainWindowView()
}

#Preview("Logo") {
    HStack(spacing: 20) {
        VoxAiGoLogo(size: 28)
        VoxAiGoLogo(size: 48)
        VoxAiGoLogo(size: 64)
        VoxAiGoLogo(size: 128)
    }
    .padding()
}
