import Foundation
import Combine

/// Representa um snippet de texto com atalho
struct Snippet: Identifiable, Codable, Equatable {
    let id: UUID
    var abbreviation: String
    var text: String
    var isEnabled: Bool
    
    init(id: UUID = UUID(), abbreviation: String, text: String, isEnabled: Bool = true) {
        self.id = id
        self.abbreviation = abbreviation
        self.text = text
        self.isEnabled = isEnabled
    }
}

/// Gerencia snippets de texto (atalhos expansíveis)
class SnippetsManager: ObservableObject {
    static let shared = SnippetsManager()
    
    @Published var snippets: [Snippet] = []
    private let saveKey = "text_snippets"
    
    private init() {
        loadSnippets()
        
        // Adicionar snippets padrão se estiver vazio
        if snippets.isEmpty {
            addDefaultSnippets()
        }
    }
    
    // MARK: - Public Methods
    
    func add(abbreviation: String, text: String) {
        let snippet = Snippet(abbreviation: abbreviation, text: text)
        snippets.append(snippet)
        saveSnippets()
    }
    
    func update(_ snippet: Snippet) {
        if let index = snippets.firstIndex(where: { $0.id == snippet.id }) {
            snippets[index] = snippet
            saveSnippets()
        }
    }
    
    func delete(_ snippet: Snippet) {
        snippets.removeAll { $0.id == snippet.id }
        saveSnippets()
    }
    
    func delete(at offsets: IndexSet) {
        snippets.remove(atOffsets: offsets)
        saveSnippets()
    }
    
    func toggleEnabled(_ snippet: Snippet) {
        if let index = snippets.firstIndex(where: { $0.id == snippet.id }) {
            snippets[index].isEnabled.toggle()
            saveSnippets()
        }
    }
    
    /// Expande uma abreviação para seu texto completo
    func expand(_ text: String) -> String {
        var result = text
        
        for snippet in snippets where snippet.isEnabled {
            // Procura por :abbreviation: e substitui
            let pattern = ":\(snippet.abbreviation):"
            result = result.replacingOccurrences(of: pattern, with: snippet.text)
        }
        
        return result
    }
    
    // MARK: - Private Methods
    
    private func addDefaultSnippets() {
        let defaults = [
            Snippet(abbreviation: "email", text: "seu.email@exemplo.com"),
            Snippet(abbreviation: "tel", text: "(11) 99999-9999"),
            Snippet(abbreviation: "ende", text: "Rua Exemplo, 123 - São Paulo, SP"),
            Snippet(abbreviation: "data", text: "{{data}}"),
            Snippet(abbreviation: "hora", text: "{{hora}}")
        ]
        
        snippets = defaults
        saveSnippets()
    }
    
    private func saveSnippets() {
        guard let data = try? JSONEncoder().encode(snippets) else { return }
        UserDefaults.standard.set(data, forKey: saveKey)
    }
    
    private func loadSnippets() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let savedSnippets = try? JSONDecoder().decode([Snippet].self, from: data) else {
            return
        }
        snippets = savedSnippets
    }
}
