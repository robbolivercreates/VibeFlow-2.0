import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(L10n.home, systemImage: "house.fill")
                }
                .tag(0)

            SettingsView()
                .tabItem {
                    Label(L10n.settings, systemImage: "gearshape.fill")
                }
                .tag(1)
        }
        .tint(.orange)
    }
}

// MARK: - Home View

struct HomeView: View {
    @State private var settings = SharedSettings.shared
    @State private var showingAPIKeyAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Status Card
                    statusCard

                    // Quick Mode Selector
                    modeSelector

                    // Statistics
                    statisticsCard

                    // Keyboard Instructions
                    instructionsCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("VibeFlow")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !settings.hasApiKey {
                        Button {
                            showingAPIKeyAlert = true
                        } label: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
            .alert(L10n.setupRequired, isPresented: $showingAPIKeyAlert) {
                Button(L10n.settings) {
                    // Switch to settings tab
                }
                Button(L10n.back, role: .cancel) {}
            } message: {
                Text(L10n.setupRequiredDesc)
            }
        }
    }

    private var statusCard: some View {
        VStack(spacing: 16) {
            Image(systemName: settings.hasApiKey ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(settings.hasApiKey ? .green : .red)

            Text(settings.hasApiKey ? L10n.ready : L10n.setupRequired)
                .font(.title2.bold())

            Text(settings.hasApiKey ? L10n.readyDesc : L10n.setupRequiredDesc)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var modeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.transcriptionMode)
                .font(.headline)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(TranscriptionMode.allCases, id: \.self) { mode in
                    ModeButton(
                        mode: mode,
                        isSelected: settings.selectedMode == mode
                    ) {
                        withAnimation {
                            settings.selectedMode = mode
                        }
                    }
                }
            }
        }
    }

    private var statisticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.statistics)
                .font(.headline)
                .padding(.horizontal, 4)

            HStack(spacing: 16) {
                StatBox(
                    title: L10n.transcriptions,
                    value: "\(settings.totalTranscriptions)",
                    icon: "waveform"
                )

                StatBox(
                    title: L10n.currentMode,
                    value: settings.selectedMode.displayName,
                    icon: settings.selectedMode.icon
                )
            }
        }
    }

    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.howToUse)
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 12) {
                InstructionRow(number: 1, text: L10n.setupStep1)
                InstructionRow(number: 2, text: L10n.setupStep2)
                InstructionRow(number: 3, text: L10n.setupStep4)
                InstructionRow(number: 4, text: L10n.setupStep3)
                InstructionRow(number: 5, text: L10n.holdToRecord)
            }
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Supporting Views

struct ModeButton: View {
    let mode: TranscriptionMode
    let isSelected: Bool
    let action: () -> Void

    private var modeColor: Color {
        switch mode {
        case .code: return .blue
        case .text: return .green
        case .email: return .orange
        case .uxDesign: return .purple
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.title2)

                Text(mode.displayName)
                    .font(.subheadline.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? modeColor.opacity(0.15) : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? modeColor : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? modeColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.orange)

            Text(value)
                .font(.title3.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.orange)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AppState())
}
