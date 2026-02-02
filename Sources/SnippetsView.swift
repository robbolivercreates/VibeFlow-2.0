import SwiftUI

struct SnippetsView: View {
    @StateObject private var snippetService = SnippetService()
    @State private var showingAddSheet = false
    @State private var editingSnippet: Snippet?
    @State private var searchText = ""
    @State private var selectedCategory: SnippetCategory?
    
    var filteredSnippets: [Snippet] {
        var result = snippetService.snippets
        
        // Filtrar por categoria
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        // Filtrar por busca
        if !searchText.isEmpty {
            result = result.filter {
                $0.trigger.lowercased().contains(searchText.lowercased()) ||
                $0.content.lowercased().contains(searchText.lowercased())
            }
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Search e Filtros
            searchAndFilterView
            
            // Lista de Snippets
            snippetsList
        }
        .frame(minWidth: 500, minHeight: 400)
        .sheet(isPresented: $showingAddSheet) {
            SnippetEditSheet(snippet: nil, onSave: { snippet in
                snippetService.addSnippet(snippet)
            })
        }
        .sheet(item: $editingSnippet) { snippet in
            SnippetEditSheet(snippet: snippet, onSave: { updated in
                snippetService.updateSnippet(updated)
            })
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Snippets")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Diga \"snip [nome]\" para inserir rapidamente")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { showingAddSheet = true }) {
                Label("Novo", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Search e Filtros
    private var searchAndFilterView: some View {
        VStack(spacing: 8) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Buscar snippets...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)
            
            // Filtros de categoria
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryFilterButton(
                        title: "Todos",
                        isSelected: selectedCategory == nil,
                        action: { selectedCategory = nil }
                    )
                    
                    ForEach(SnippetCategory.allCases) { category in
                        CategoryFilterButton(
                            title: category.rawValue,
                            icon: category.icon,
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = category }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Lista de Snippets
    private var snippetsList: some View {
        List {
            if filteredSnippets.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("Nenhum snippet encontrado")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Button("Criar primeiro snippet") {
                            showingAddSheet = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .padding()
                }
            } else {
                // Snippets recentes
                if searchText.isEmpty && selectedCategory == nil && !snippetService.recentSnippets.isEmpty {
                    Section(header: Text("Recentes").font(.caption)) {
                        ForEach(snippetService.recentSnippets.prefix(5)) { snippet in
                            SnippetRow(
                                snippet: snippet,
                                onEdit: { editingSnippet = snippet },
                                onDelete: { snippetService.deleteSnippet(id: snippet.id) }
                            )
                        }
                    }
                }
                
                // Todos os snippets
                Section(header: Text("Todos os Snippets").font(.caption)) {
                    ForEach(filteredSnippets) { snippet in
                        SnippetRow(
                            snippet: snippet,
                            onEdit: { editingSnippet = snippet },
                            onDelete: { snippetService.deleteSnippet(id: snippet.id) }
                        )
                    }
                }
            }
            
            // Estatísticas
            if !snippetService.snippets.isEmpty {
                Section {
                    StatisticsView(statistics: snippetService.statistics)
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Componentes Auxiliares

struct CategoryFilterButton: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct SnippetRow: View {
    let snippet: Snippet
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showingPreview = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Trigger
                HStack(spacing: 4) {
                    Image(systemName: "textformat")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    
                    Text("snip \(snippet.trigger)")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // Badge de categoria
                HStack(spacing: 4) {
                    Image(systemName: snippet.category.icon)
                        .font(.caption2)
                    Text(snippet.category.rawValue)
                        .font(.caption2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.accentColor.opacity(0.1))
                .foregroundColor(.accentColor)
                .cornerRadius(4)
                
                // Contador de uso
                if snippet.usageCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "number")
                            .font(.caption2)
                        Text("\(snippet.usageCount)")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            // Preview do conteúdo
            Text(snippet.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .truncationMode(.tail)
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button(action: onEdit) {
                Label("Editar", systemImage: "pencil")
            }
            
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(snippet.content, forType: .string)
            }) {
                Label("Copiar conteúdo", systemImage: "doc.on.doc")
            }
            
            Divider()
            
            Button(role: .destructive, action: onDelete) {
                Label("Excluir", systemImage: "trash")
            }
        }
        .onTapGesture {
            showingPreview = true
        }
        .sheet(isPresented: $showingPreview) {
            SnippetPreviewSheet(snippet: snippet, onEdit: onEdit)
        }
    }
}

struct StatisticsView: View {
    let statistics: SnippetStatistics
    
    var body: some View {
        HStack(spacing: 16) {
            StatBox(title: "Total", value: "\(statistics.totalSnippets)", icon: "text.bubble")
            StatBox(title: "Usos", value: "\(statistics.totalUses)", icon: "number")
            
            if let mostUsed = statistics.mostUsedSnippet, mostUsed.usageCount > 0 {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mais usado")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("snip \(mostUsed.trigger)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(minWidth: 60)
    }
}

// MARK: - Sheets

struct SnippetEditSheet: View {
    let snippet: Snippet?
    let onSave: (Snippet) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var trigger = ""
    @State private var content = ""
    @State private var category: SnippetCategory = .custom
    
    var isEditing: Bool { snippet != nil }
    
    init(snippet: Snippet?, onSave: @escaping (Snippet) -> Void) {
        self.snippet = snippet
        self.onSave = onSave
        
        if let snippet = snippet {
            _trigger = State(initialValue: snippet.trigger)
            _content = State(initialValue: snippet.content)
            _category = State(initialValue: snippet.category)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Comando de Voz")) {
                    HStack {
                        Text("snip")
                            .foregroundColor(.secondary)
                        TextField("nome", text: $trigger)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Text("Diga \"snip \(trigger.isEmpty ? "nome" : trigger)\" para ativar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Conteúdo")) {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("Categoria")) {
                    Picker("Categoria", selection: $category) {
                        ForEach(SnippetCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Preview
                if !trigger.isEmpty && !content.isEmpty {
                    Section(header: Text("Preview")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Você diz:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\"snip \(trigger)\"")
                                .font(.system(.body, design: .monospaced))
                                .padding(8)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(4)
                            
                            Text("VibeFlow insere:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(content)
                                .font(.body)
                                .padding(8)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(isEditing ? "Editar Snippet" : "Novo Snippet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        let newSnippet = Snippet(
                            id: snippet?.id ?? UUID(),
                            trigger: trigger,
                            content: content,
                            category: category,
                            usageCount: snippet?.usageCount ?? 0,
                            lastUsed: snippet?.lastUsed,
                            createdAt: snippet?.createdAt ?? Date(),
                            isEnabled: snippet?.isEnabled ?? true
                        )
                        onSave(newSnippet)
                        dismiss()
                    }
                    .disabled(trigger.isEmpty || content.isEmpty)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 400)
    }
}

struct SnippetPreviewSheet: View {
    let snippet: Snippet
    let onEdit: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        Label(snippet.category.rawValue, systemImage: snippet.category.icon)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundColor(.accentColor)
                            .cornerRadius(4)
                        
                        Spacer()
                        
                        if snippet.usageCount > 0 {
                            Label("\(snippet.usageCount) usos", systemImage: "number")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Comando
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Comando de voz")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("snip \(snippet.trigger)")
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Conteúdo
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Conteúdo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(snippet.content)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                    }
                    
                    // Metadados
                    HStack {
                        Text("Criado em \(snippet.createdAt, style: .date)")
                        
                        if let lastUsed = snippet.lastUsed {
                            Spacer()
                            Text("Último uso: \(lastUsed, style: .relative) atrás")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Snippet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        dismiss()
                        onEdit()
                    }) {
                        Label("Editar", systemImage: "pencil")
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

// MARK: - Preview

struct SnippetsView_Previews: PreviewProvider {
    static var previews: some View {
        SnippetsView()
    }
}
