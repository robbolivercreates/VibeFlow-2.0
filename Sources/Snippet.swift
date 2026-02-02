import Foundation

/// Representa um atalho de texto (snippet) que expande para conteúdo completo
struct Snippet: Codable, Identifiable, Equatable {
    var id: UUID
    var trigger: String      // Palavra de ativação (ex: "endereco")
    var content: String      // Texto completo expandido
    var category: SnippetCategory
    var usageCount: Int      // Contador de uso para analytics
    var lastUsed: Date?      // Último uso
    var createdAt: Date      // Data de criação
    var isEnabled: Bool      // Se está ativo
    
    init(
        id: UUID = UUID(),
        trigger: String,
        content: String,
        category: SnippetCategory = .custom,
        usageCount: Int = 0,
        lastUsed: Date? = nil,
        createdAt: Date = Date(),
        isEnabled: Bool = true
    ) {
        self.id = id
        self.trigger = trigger.lowercased().trimmingCharacters(in: .whitespaces)
        self.content = content
        self.category = category
        self.usageCount = usageCount
        self.lastUsed = lastUsed
        self.createdAt = createdAt
        self.isEnabled = isEnabled
    }
    
    /// Prefixo para ativar snippets durante a fala
    static let activationPrefix = "snip "
    
    /// Verifica se um texto ativa este snippet
    func matches(input: String) -> Bool {
        let cleanInput = input.lowercased().trimmingCharacters(in: .whitespaces)
        return cleanInput == "\(Snippet.activationPrefix)\(trigger)" ||
               cleanInput == trigger
    }
}

/// Categorias de snippets para organização
enum SnippetCategory: String, Codable, CaseIterable, Identifiable {
    case personal = "Pessoal"
    case work = "Trabalho"
    case code = "Código"
    case email = "Email"
    case custom = "Personalizado"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .personal: return "person.fill"
        case .work: return "briefcase.fill"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .email: return "envelope.fill"
        case .custom: return "star.fill"
        }
    }
    
    var color: String {
        switch self {
        case .personal: return "blue"
        case .work: return "orange"
        case .code: return "green"
        case .email: return "purple"
        case .custom: return "gray"
        }
    }
}

// MARK: - Snippets Padrão (Exemplos)

extension Snippet {
    /// Snippets padrão sugeridos para novos usuários
    static var defaultSnippets: [Snippet] {
        [
            Snippet(
                trigger: "assinatura",
                content: "Atenciosamente,\n[Seu Nome]",
                category: .email
            ),
            Snippet(
                trigger: "tel",
                content: "(11) 99999-9999",
                category: .personal
            ),
            Snippet(
                trigger: "email",
                content: "seu.email@exemplo.com",
                category: .personal
            ),
            Snippet(
                trigger: "github",
                content: "https://github.com/seuusuario",
                category: .work
            ),
            Snippet(
                trigger: "lorem",
                content: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                category: .custom
            ),
            Snippet(
                trigger: "todo",
                content: "- [ ] Tarefa pendente\n- [ ] Outra tarefa\n- [ ] Mais uma tarefa",
                category: .work
            ),
            Snippet(
                trigger: "review",
                content: "## Code Review\n\n### Pontos Positivos\n- \n\n### Sugestões\n- \n\n### Aprovação\n- [ ] Aprovado\n- [ ] Aprovado com sugestões\n- [ ] Requer mudanças",
                category: .code
            )
        ]
    }
}
