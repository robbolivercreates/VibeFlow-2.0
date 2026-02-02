import SwiftUI

/// View de gerenciamento de snippets
struct SnippetsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var snippets = SnippetsManager.shared
    @State private var showingAddSheet = false
    @State private var editingSnippet: Snippet?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Snippets")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("+ Novo") {
                    showingAddSheet = true
                }
                
                Button("Fechar") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            
            // Descrição
            Text("Use :abbreviation: no texto transcrito para expandir automaticamente.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            // Lista
            List {
                ForEach(snippets.snippets) { snippet in
                    SnippetRow(snippet: snippet)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingSnippet = snippet
                        }
                        .contextMenu {
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
                        }
                }
                .onDelete(perform: snippets.delete)
            }
            .listStyle(.plain)
        }
        .frame(width: 450, height: 450)
        .sheet(isPresented: $showingAddSheet) {
            SnippetEditView()
        }
        .sheet(item: $editingSnippet) { snippet in
            SnippetEditView(snippet: snippet)
        }
    }
}

// MARK: - Snippet Row

struct SnippetRow: View {
    let snippet: Snippet
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(":\(snippet.abbreviation):")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                    
                    if !snippet.isEnabled {
                        Text("desativado")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(3)
                    }
                }
                
                Text(snippet.text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: snippet.isEnabled ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(snippet.isEnabled ? .green : .secondary)
        }
        .padding(.vertical, 4)
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
