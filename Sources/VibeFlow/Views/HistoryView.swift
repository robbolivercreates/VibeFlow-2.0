import SwiftUI

/// View do histórico de transcrições
struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var history = HistoryManager.shared
    @State private var selectedItem: HistoryItem?
    @State private var searchText = ""
    @State private var showingDeleteConfirmation = false
    
    var filteredItems: [HistoryItem] {
        if searchText.isEmpty {
            return history.items
        }
        return history.items.filter { item in
            item.text.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Histórico")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(history.items.count) itens salvos")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
                .disabled(history.items.isEmpty)
                .help("Limpar todo o histórico")
                
                Button("Fechar") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Buscar no histórico...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Lista
            if history.items.isEmpty {
                emptyState
            } else if filteredItems.isEmpty {
                noResultsState
            } else {
                List(selection: $selectedItem) {
                    ForEach(filteredItems) { item in
                        HistoryItemRow(item: item, isSelected: selectedItem?.id == item.id)
                            .tag(item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedItem = item
                            }
                            .contextMenu {
                                Button {
                                    history.copyToClipboard(item)
                                } label: {
                                    Label("Copiar", systemImage: "doc.on.doc")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    history.delete(item: item)
                                } label: {
                                    Label("Excluir", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete(perform: history.delete)
                }
                .listStyle(.plain)
            }
            
            // Footer com preview do item selecionado
            if let item = selectedItem {
                selectedItemPreview(item)
            }
        }
        .frame(width: 550, height: 600)
        .alert("Limpar histórico?", isPresented: $showingDeleteConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Limpar tudo", role: .destructive) {
                history.clear()
                selectedItem = nil
            }
        } message: {
            Text("Isso excluirá permanentemente todos os \(history.items.count) itens do histórico.")
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 50))
                .foregroundStyle(.secondary.opacity(0.5))
            
            Text("Nenhum item no histórico")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("Suas transcrições aparecerão aqui")
                .font(.caption)
                .foregroundStyle(.secondary.opacity(0.7))
        }
        .frame(maxHeight: .infinity)
    }
    
    private var noResultsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(.secondary.opacity(0.5))
            
            Text("Nenhum resultado encontrado")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
    
    private func selectedItemPreview(_ item: HistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(item.text)
                        .font(.body)
                        .lineLimit(3)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Button {
                        history.copyToClipboard(item)
                    } label: {
                        Label("Copiar", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    Button {
                        history.delete(item: item)
                        selectedItem = nil
                    } label: {
                        Label("Excluir", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundStyle(.red)
                }
            }
            .padding()
        }
        .background(Color.secondary.opacity(0.05))
    }
}

// MARK: - History Item Row

struct HistoryItemRow: View {
    let item: HistoryItem
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Ícone do modo
            modeIcon
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.mode.localizedName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(modeColor)
                    
                    Spacer()
                    
                    Text(item.formattedTime)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Text(previewText)
                    .font(.body)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .contentShape(Rectangle())
    }
    
    private var modeIcon: some View {
        ZStack {
            Circle()
                .fill(modeColor.opacity(0.15))
                .frame(width: 36, height: 36)
            
            Image(systemName: item.mode.icon)
                .font(.system(size: 14))
                .foregroundStyle(modeColor)
        }
    }
    
    private var modeColor: Color {
        switch item.mode {
        case .code:
            return .blue
        case .text:
            return .green
        case .email:
            return .orange
        case .uxDesign:
            return .purple
        }
    }
    
    private var previewText: String {
        let maxLength = 120
        if item.text.count > maxLength {
            return String(item.text.prefix(maxLength)) + "..."
        }
        return item.text
    }
}

#Preview {
    HistoryView()
}
