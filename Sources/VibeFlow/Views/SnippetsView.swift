import SwiftUI

/// View de gerenciamento de snippets — matches the visual pattern of other sidebar pages
struct SnippetsView: View {
    @StateObject private var snippets = SnippetsManager.shared
    @StateObject private var subscription = SubscriptionManager.shared
    @State private var showingAddSheet = false
    @State private var editingSnippet: Snippet?
    @State private var showUpgradeModal = false

    private var isFreeTier: Bool {
        !subscription.isPro && !TrialManager.shared.isTrialActive()
    }

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
                    // Quick add
                    addSnippetCard

                    // Snippets list
                    snippetsListSection

                    // Tips
                    tipSection
                }
                .padding(32)
            }
            .clipped()
        }
        .background(VoxTheme.background)
        .sheet(isPresented: $showingAddSheet) {
            SnippetEditView()
        }
        .sheet(item: $editingSnippet) { snippet in
            SnippetEditView(snippet: snippet)
        }
        .sheet(isPresented: $showUpgradeModal) {
            UpgradeModalView(isPresented: $showUpgradeModal, context: .snippets)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Snippets")
                    .font(.system(size: 28, weight: .bold))

                Spacer()

                Button(action: {
                    if isFreeTier {
                        showUpgradeModal = true
                    } else {
                        showingAddSheet = true
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isFreeTier ? "lock.fill" : "plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Novo")
                            .font(.system(size: 13, weight: .medium))
                        if isFreeTier {
                            HStack(spacing: 2) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 7))
                                Text("PRO")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.3))
                            .cornerRadius(3)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(isFreeTier ? VoxTheme.accent.opacity(0.5) : VoxTheme.accent)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            Text("Use :abreviacao: no texto transcrito para expandir automaticamente.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Add Snippet Card

    private var addSnippetCard: some View {
        Button(action: {
            if isFreeTier {
                showUpgradeModal = true
            } else {
                showingAddSheet = true
            }
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isFreeTier ? Color.gray.opacity(0.15) : VoxTheme.accent.opacity(0.15))
                        .frame(width: 44, height: 44)

                    if isFreeTier {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(VoxTheme.accent)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Criar Snippet")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(isFreeTier ? .secondary : .primary)
                        if isFreeTier {
                            HStack(spacing: 3) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 8))
                                Text("PRO")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(VoxTheme.goldGradient)
                            .cornerRadius(4)
                        }
                    }

                    Text("Adicione uma abreviacao para expandir automaticamente")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(VoxTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(VoxTheme.accent.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Snippets List

    private var snippetsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Seus Snippets")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(snippets.snippets.count) snippet\(snippets.snippets.count == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            if snippets.snippets.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(snippets.snippets.enumerated()), id: \.element.id) { index, snippet in
                        SnippetRow(snippet: snippet)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isFreeTier {
                                    showUpgradeModal = true
                                } else {
                                    editingSnippet = snippet
                                }
                            }
                            .contextMenu {
                                if !isFreeTier {
                                    Button("Editar") {
                                        editingSnippet = snippet
                                    }

                                    Toggle("Ativado", isOn: .init(
                                        get: { snippet.isEnabled },
                                        set: { _ in snippets.toggleEnabled(snippet) }
                                    ))

                                    Divider()

                                    Button("Excluir") {
                                        snippets.delete(snippet)
                                    }
                                } else {
                                    Button("Upgrade para Pro") {
                                        showUpgradeModal = true
                                    }
                                }
                            }

                        if index < snippets.snippets.count - 1 {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(VoxTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(VoxTheme.surfaceBorder, lineWidth: 1)
                )
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text("Nenhum snippet ainda")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)

                Text("Crie um snippet para expandir abreviacoes automaticamente")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(VoxTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(VoxTheme.surfaceBorder, lineWidth: 1)
                )
        )
    }

    // MARK: - Tips

    private var tipSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(VoxTheme.accent)
                Text("Dica")
                    .font(.system(size: 12, weight: .medium))
            }

            Text("Ao transcrever, use :abreviacao: no texto para expandir automaticamente. Por exemplo, diga \"meu email e :email:\" para expandir com seu snippet.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(VoxTheme.accent.opacity(0.08))
        .cornerRadius(8)
    }
}

// MARK: - Snippet Row

struct SnippetRow: View {
    let snippet: Snippet

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Image(systemName: "text.badge.plus")
                .font(.system(size: 14))
                .foregroundStyle(VoxTheme.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(":\(snippet.abbreviation):")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))

                    if !snippet.isEnabled {
                        Text("desativado")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(VoxTheme.surfaceBorder)
                            .cornerRadius(3)
                    }
                }

                Text(snippet.text)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: snippet.isEnabled ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16))
                .foregroundStyle(snippet.isEnabled ? VoxTheme.accent : .secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .opacity(snippet.isEnabled ? 1.0 : 0.6)
    }
}

// MARK: - Snippet Edit View

struct SnippetEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var snippets = SnippetsManager.shared

    var snippet: Snippet?

    @State private var abbreviation = ""
    @State private var text = ""
    @State private var isEnabled = true

    var isEditing: Bool { snippet != nil }

    var body: some View {
        VStack(spacing: 20) {
            Text(isEditing ? "Editar Snippet" : "Novo Snippet")
                .font(.title2)
                .fontWeight(.bold)

            Form {
                TextField("Abreviação", text: $abbreviation)
                    .textFieldStyle(.roundedBorder)

                Text("Use :sua-abreviacao: no texto para expandir")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextEditor(text: $text)
                    .frame(height: 100)
                    .font(.body)

                Toggle("Ativado", isOn: $isEnabled)
            }

            HStack {
                Button("Cancelar") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                Button(isEditing ? "Salvar" : "Criar") {
                    save()
                }
                .keyboardShortcut(.return, modifiers: .command)
                .buttonStyle(.borderedProminent)
                .disabled(abbreviation.isEmpty || text.isEmpty)
            }
        }
        .padding()
        .frame(width: 350, height: 300)
        .onAppear {
            if let snippet = snippet {
                abbreviation = snippet.abbreviation
                text = snippet.text
                isEnabled = snippet.isEnabled
            }
        }
    }

    private func save() {
        let cleanAbbreviation = abbreviation
            .replacingOccurrences(of: ":", with: "")
            .trimmingCharacters(in: .whitespaces)

        if let existing = snippet {
            var updated = existing
            updated.abbreviation = cleanAbbreviation
            updated.text = text
            updated.isEnabled = isEnabled
            snippets.update(updated)
        } else {
            snippets.add(abbreviation: cleanAbbreviation, text: text)
        }

        dismiss()
    }
}

#Preview {
    SnippetsView()
}
