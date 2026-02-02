import Foundation
import Combine

/// Serviço responsável por gerenciar snippets (atalhos de texto)
class SnippetService: ObservableObject {
    @Published var snippets: [Snippet] = []
    @Published var recentSnippets: [Snippet] = []
    
    private let userDefaultsKey = "vibeflow.snippets"
    private let recentKey = "vibeflow.recentSnippets"
    private let maxRecentItems = 10
    
    init() {
        loadSnippets()
        loadRecentSnippets()
    }
    
    // MARK: - CRUD Operations
    
    /// Adiciona um novo snippet
    func addSnippet(_ snippet: Snippet) {
        // Verificar se já existe trigger igual
        if snippets.contains(where: { $0.trigger == snippet.trigger && $0.id != snippet.id }) {
            return
        }
        
        snippets.append(snippet)
        saveSnippets()
    }
    
    /// Atualiza um snippet existente
    func updateSnippet(_ snippet: Snippet) {
        guard let index = snippets.firstIndex(where: { $0.id == snippet.id }) else { return }
        
        // Verificar se o novo trigger não conflita com outro
        let otherSnippet = snippets.first { $0.trigger == snippet.trigger && $0.id != snippet.id }
        if otherSnippet != nil { return }
        
        snippets[index] = snippet
        saveSnippets()
    }
    
    /// Remove um snippet
    func deleteSnippet(id: UUID) {
        snippets.removeAll { $0.id == id }
        saveSnippets()
    }
    
    /// Move snippets (para reorder)
    func moveSnippets(from source: IndexSet, to destination: Int) {
        snippets.move(fromOffsets: source, toOffset: destination)
        saveSnippets()
    }
    
    // MARK: - Busca e Expansão
    
    /// Verifica se o texto de entrada corresponde a um snippet
    func findMatchingSnippet(for input: String) -> Snippet? {
        let cleanInput = input.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Verificar prefixo "snip "
        let searchTerm: String
        if cleanInput.hasPrefix(Snippet.activationPrefix) {
            searchTerm = String(cleanInput.dropFirst(Snippet.activationPrefix.count))
        } else {
            searchTerm = cleanInput
        }
        
        return snippets.first { snippet in
            snippet.isEnabled && snippet.trigger == searchTerm
        }
    }
    
    /// Expande um snippet e atualiza estatísticas
    func expandSnippet(_ snippet: Snippet) -> String {
        // Atualizar estatísticas
        if let index = snippets.firstIndex(where: { $0.id == snippet.id }) {
            var updatedSnippet = snippets[index]
            updatedSnippet.usageCount += 1
            updatedSnippet.lastUsed = Date()
            snippets[index] = updatedSnippet
            saveSnippets()
            
            // Adicionar aos recentes
            addToRecent(updatedSnippet)
        }
        
        return snippet.content
    }
    
    /// Processa texto de entrada e expande snippets se encontrados
    func processInput(_ input: String) -> String {
        // Se corresponde a um snippet, expandir
        if let snippet = findMatchingSnippet(for: input) {
            return expandSnippet(snippet)
        }
        
        // Retornar texto original se não for snippet
        return input
    }
    
    /// Verifica se o texto parece ser um comando de snippet
    func isSnippetCommand(_ input: String) -> Bool {
        let cleanInput = input.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Se começa com "snip "
        if cleanInput.hasPrefix(Snippet.activationPrefix) {
            let trigger = String(cleanInput.dropFirst(Snippet.activationPrefix.count))
            return snippets.contains { $0.isEnabled && $0.trigger == trigger }
        }
        
        // Ou se corresponde exatamente a um trigger
        return snippets.contains { $0.isEnabled && $0.trigger == cleanInput }
    }
    
    // MARK: - Snippets Recentes
    
    private func addToRecent(_ snippet: Snippet) {
        // Remover se já existe
        recentSnippets.removeAll { $0.id == snippet.id }
        
        // Adicionar no início
        recentSnippets.insert(snippet, at: 0)
        
        // Limitar tamanho
        if recentSnippets.count > maxRecentItems {
            recentSnippets = Array(recentSnippets.prefix(maxRecentItems))
        }
        
        saveRecentSnippets()
    }
    
    // MARK: - Categorias
    
    /// Retorna snippets filtrados por categoria
    func snippets(for category: SnippetCategory) -> [Snippet] {
        snippets.filter { $0.category == category }
    }
    
    /// Retorna todas as categorias que têm snippets
    var activeCategories: [SnippetCategory] {
        SnippetCategory.allCases.filter { category in
            snippets.contains { $0.category == category }
        }
    }
    
    /// Busca snippets por texto
    func searchSnippets(query: String) -> [Snippet] {
        let lowerQuery = query.lowercased()
        return snippets.filter { snippet in
            snippet.trigger.lowercased().contains(lowerQuery) ||
            snippet.content.lowercased().contains(lowerQuery)
        }
    }
    
    // MARK: - Import/Export
    
    /// Exporta snippets para JSON
    func exportToJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(snippets)
    }
    
    /// Importa snippets de JSON
    func importFromJSON(_ data: Data) -> Bool {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let importedSnippets = try? decoder.decode([Snippet].self, from: data) else {
            return false
        }
        
        // Mesclar com existentes (evitar duplicados por trigger)
        for snippet in importedSnippets {
            if !snippets.contains(where: { $0.trigger == snippet.trigger }) {
                var newSnippet = snippet
                newSnippet.id = UUID() // Novo ID para evitar conflitos
                snippets.append(newSnippet)
            }
        }
        
        saveSnippets()
        return true
    }
    
    /// Reseta para snippets padrão
    func resetToDefaults() {
        snippets = Snippet.defaultSnippets
        saveSnippets()
    }
    
    // MARK: - Persistência
    
    private func saveSnippets() {
        if let encoded = try? JSONEncoder().encode(snippets) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadSnippets() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([Snippet].self, from: data) else {
            // Primeira vez - carregar padrões
            snippets = Snippet.defaultSnippets
            return
        }
        snippets = decoded
    }
    
    private func saveRecentSnippets() {
        if let encoded = try? JSONEncoder().encode(recentSnippets) {
            UserDefaults.standard.set(encoded, forKey: recentKey)
        }
    }
    
    private func loadRecentSnippets() {
        guard let data = UserDefaults.standard.data(forKey: recentKey),
              let decoded = try? JSONDecoder().decode([Snippet].self, from: data) else {
            return
        }
        recentSnippets = decoded
    }
    
    // MARK: - Estatísticas
    
    /// Estatísticas de uso
    var statistics: SnippetStatistics {
        let totalUses = snippets.reduce(0) { $0 + $1.usageCount }
        let mostUsed = snippets.max { $0.usageCount < $1.usageCount }
        let byCategory = Dictionary(grouping: snippets) { $0.category }
            .mapValues { $0.reduce(0) { $0 + $1.usageCount } }
        
        return SnippetStatistics(
            totalSnippets: snippets.count,
            totalUses: totalUses,
            mostUsedSnippet: mostUsed,
            usesByCategory: byCategory
        )
    }
}

// MARK: - Estatísticas

struct SnippetStatistics {
    let totalSnippets: Int
    let totalUses: Int
    let mostUsedSnippet: Snippet?
    let usesByCategory: [SnippetCategory: Int]
}
