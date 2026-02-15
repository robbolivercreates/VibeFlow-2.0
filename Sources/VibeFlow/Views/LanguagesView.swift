import SwiftUI

/// Languages management view
struct LanguagesView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var searchText = ""

    private var filteredLanguages: [SpeechLanguage] {
        if searchText.isEmpty {
            return SpeechLanguage.allCases
        }
        return SpeechLanguage.allCases.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Header
                headerSection

                // MARK: - Current Language
                currentLanguageSection

                // MARK: - Favorites
                favoritesSection

                // MARK: - All Languages
                allLanguagesSection
            }
            .padding(32)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Idiomas")
                .font(.system(size: 28, weight: .bold))

            Text("Configure o idioma de saida das suas transcricoes. Voce pode falar em qualquer idioma - o VibeFlow traduz automaticamente.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Current Language

    private var currentLanguageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Idioma Atual")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                // Current language display
                HStack(spacing: 12) {
                    Text(settings.outputLanguage.flag)
                        .font(.system(size: 32))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(settings.outputLanguage.displayName)
                            .font(.system(size: 16, weight: .semibold))

                        Text(settings.outputLanguage.rawValue.uppercased())
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Shortcut hint
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Atalho para alternar")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    Text("⌃⇧L")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(.purple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Favorites

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Favoritos")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(settings.favoriteLanguages.count) idiomas")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Text("Use ⌃⇧L para alternar rapidamente entre seus idiomas favoritos.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            // Favorites list
            FlowLayout(spacing: 8) {
                ForEach(settings.favoriteLanguages) { language in
                    FavoriteLanguageChip(
                        language: language,
                        isSelected: language == settings.outputLanguage,
                        onSelect: { settings.outputLanguage = language },
                        onRemove: { removeFavorite(language) }
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
    }

    // MARK: - All Languages

    private var allLanguagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Todos os Idiomas")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                // Search
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    TextField("Buscar...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .frame(width: 120)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
            }

            // Languages grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(filteredLanguages) { language in
                    LanguageRow(
                        language: language,
                        isSelected: language == settings.outputLanguage,
                        isFavorite: settings.favoriteLanguages.contains(language),
                        onSelect: { settings.outputLanguage = language },
                        onToggleFavorite: { toggleFavorite(language) }
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
    }

    // MARK: - Actions

    private func toggleFavorite(_ language: SpeechLanguage) {
        if settings.favoriteLanguages.contains(language) {
            removeFavorite(language)
        } else {
            settings.favoriteLanguages.append(language)
            settings.favoriteLanguages.sort { $0.displayName < $1.displayName }
        }
    }

    private func removeFavorite(_ language: SpeechLanguage) {
        guard settings.favoriteLanguages.count > 1 else { return }
        settings.favoriteLanguages.removeAll { $0 == language }
    }
}

// MARK: - Favorite Language Chip

struct FavoriteLanguageChip: View {
    let language: SpeechLanguage
    let isSelected: Bool
    let onSelect: () -> Void
    let onRemove: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onSelect) {
                HStack(spacing: 6) {
                    Text(language.flag)
                        .font(.system(size: 16))

                    Text(language.displayName)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                }
            }
            .buttonStyle(.plain)

            if isHovered {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.purple.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.purple.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Language Row

struct LanguageRow: View {
    let language: SpeechLanguage
    let isSelected: Bool
    let isFavorite: Bool
    let onSelect: () -> Void
    let onToggleFavorite: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Text(language.flag)
                .font(.system(size: 18))

            VStack(alignment: .leading, spacing: 2) {
                Text(language.displayName)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .purple : .primary)

                Text(language.rawValue.uppercased())
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Favorite star
            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 12))
                    .foregroundStyle(isFavorite ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
            .opacity(isHovered || isFavorite ? 1 : 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.purple.opacity(0.1) : (isHovered ? Color(nsColor: .controlColor).opacity(0.1) : Color.clear))
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Flow Layout (for chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > width && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: width, height: y + lineHeight)
        }
    }
}

#Preview {
    LanguagesView()
        .frame(width: 600, height: 700)
}
