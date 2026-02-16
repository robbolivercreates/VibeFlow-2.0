import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
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
            .alert("API Key Required", isPresented: $showingAPIKeyAlert) {
                Button("Go to Settings") {
                    // Switch to settings tab
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please add your Gemini API key in Settings to use VibeFlow.")
            }
        }
    }

    private var statusCard: some View {
        VStack(spacing: 16) {
            Image(systemName: settings.hasApiKey ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(settings.hasApiKey ? .green : .red)

            Text(settings.hasApiKey ? "Ready to Use" : "Setup Required")
                .font(.title2.bold())

            Text(settings.hasApiKey
                 ? "Switch to VibeFlow keyboard in any app and tap the mic to transcribe."
                 : "Add your Gemini API key in Settings to get started.")
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
            Text("Transcription Mode")
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
            Text("Statistics")
                .font(.headline)
                .padding(.horizontal, 4)

            HStack(spacing: 16) {
                StatBox(
                    title: "Transcriptions",
                    value: "\(settings.totalTranscriptions)",
                    icon: "waveform"
                )

                StatBox(
                    title: "Current Mode",
                    value: settings.selectedMode.displayName,
                    icon: settings.selectedMode.icon
                )
            }
        }
    }

    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How to Use")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 12) {
                InstructionRow(number: 1, text: "Go to Settings > General > Keyboard > Keyboards")
                InstructionRow(number: 2, text: "Tap \"Add New Keyboard\" and select VibeFlow")
                InstructionRow(number: 3, text: "Enable \"Allow Full Access\" for microphone")
                InstructionRow(number: 4, text: "In any app, switch to VibeFlow keyboard")
                InstructionRow(number: 5, text: "Tap and hold the mic button to record")
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
