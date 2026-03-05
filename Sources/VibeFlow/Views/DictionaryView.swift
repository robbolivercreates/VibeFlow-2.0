import SwiftUI

/// Custom dictionary management view — word replacements and forbidden terms
struct DictionaryView: View {
    @StateObject private var dictionary = CustomDictionaryManager.shared

    @State private var newWrong = ""
    @State private var newCorrect = ""
    @State private var newForbidden = ""
    @State private var showingClearConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Fixed header
            headerSection
                .padding(.horizontal, 32)
                .padding(.top, 32)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(VoxTheme.background)
                .zIndex(1)

            Divider()

            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    replacementsSection
                    forbiddenSection
                }
                .padding(32)
            }
            .clipped()
        }
        .background(VoxTheme.background)
        .alert("Clear Dictionary", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                dictionary.clearAll()
            }
        } message: {
            Text("This will remove all word corrections and forbidden terms.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Custom Dictionary")
                    .font(.system(size: 28, weight: .bold))

                Spacer()

                if dictionary.totalEntries > 0 {
                    Button(action: { showingClearConfirmation = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                            Text("Clear All")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Teach VoxAiGo your preferred words and terms. Add corrections for names it often gets wrong, or forbid words you never want in your output.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Word Replacements

    private var replacementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Word Corrections", systemImage: "arrow.right.arrow.left")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            // Add new replacement
            HStack(spacing: 8) {
                TextField("Wrong word...", text: $newWrong)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13))

                Image(systemName: "arrow.right")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                TextField("Correct word...", text: $newCorrect)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13))

                Button(action: addReplacement) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(VoxTheme.accent)
                }
                .buttonStyle(.plain)
                .disabled(newWrong.trimmingCharacters(in: .whitespaces).isEmpty ||
                          newCorrect.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(VoxTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(VoxTheme.accent.opacity(0.2), lineWidth: 1)
            )

            // List of replacements
            if dictionary.replacements.isEmpty {
                emptyCard(
                    icon: "character.textbox",
                    title: "No corrections yet",
                    subtitle: "Add words that VoxAiGo often gets wrong, like names or technical terms."
                )
            } else {
                VStack(spacing: 6) {
                    ForEach(dictionary.replacements) { replacement in
                        HStack(spacing: 10) {
                            Text(replacement.wrong)
                                .font(.system(size: 13))
                                .foregroundStyle(.red.opacity(0.8))
                                .strikethrough()

                            Image(systemName: "arrow.right")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)

                            Text(replacement.correct)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.green)

                            Spacer()

                            Button(action: { dictionary.removeReplacement(replacement) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(VoxTheme.surface)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Forbidden Words

    private var forbiddenSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Forbidden Words", systemImage: "nosign")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            // Add new forbidden word
            HStack(spacing: 8) {
                TextField("Word to never use...", text: $newForbidden)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13))
                    .onSubmit { addForbidden() }

                Button(action: addForbidden) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(VoxTheme.accent)
                }
                .buttonStyle(.plain)
                .disabled(newForbidden.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(VoxTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(VoxTheme.accent.opacity(0.2), lineWidth: 1)
            )

            // List of forbidden words
            if dictionary.forbidden.isEmpty {
                emptyCard(
                    icon: "text.badge.xmark",
                    title: "No forbidden words",
                    subtitle: "Add words or phrases you never want VoxAiGo to use in your output."
                )
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(dictionary.forbidden) { word in
                        HStack(spacing: 6) {
                            Image(systemName: "nosign")
                                .font(.system(size: 9))
                            Text(word.word)
                                .font(.system(size: 13))

                            Button(action: { dictionary.removeForbidden(word) }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.red.opacity(0.1))
                        )
                        .overlay(
                            Capsule()
                                .stroke(.red.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func emptyCard(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(VoxTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(VoxTheme.surfaceBorder, lineWidth: 1)
                )
        )
    }

    private func addReplacement() {
        dictionary.addReplacement(wrong: newWrong, correct: newCorrect)
        newWrong = ""
        newCorrect = ""
    }

    private func addForbidden() {
        dictionary.addForbidden(word: newForbidden)
        newForbidden = ""
    }
}


#Preview {
    DictionaryView()
        .frame(width: 600, height: 700)
}
