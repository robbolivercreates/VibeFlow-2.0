import Foundation

/// Modos de transcrição disponíveis
enum TranscriptionMode: String, CaseIterable, Identifiable, Codable {
    case code = "Código"
    case text = "Texto"
    case uxDesign = "UX Design"
    
    var id: String { rawValue }
    
    /// Ícone SF Symbol para o modo
    var icon: String {
        switch self {
        case .code:
            return "chevron.left.forwardslash.chevron.right"
        case .text:
            return "text.alignleft"
        case .uxDesign:
            return "paintbrush.pointed"
        }
    }
    
    /// Descrição curta do modo
    var shortDescription: String {
        switch self {
        case .code:
            return L10n.codeMode
        case .text:
            return L10n.textMode
        case .uxDesign:
            return "UX"
        }
    }
    
    /// Nome localizado
    var localizedName: String {
        switch self {
        case .code:
            return L10n.codeMode
        case .text:
            return L10n.textMode
        case .uxDesign:
            return L10n.uxMode
        }
    }
    
    /// Prompt do sistema para o Gemini
    func systemPrompt(translateToEnglish: Bool, clarifyText: Bool) -> String {
        let basePrompt: String
        
        switch self {
        case .code:
            basePrompt = """
            Você é um assistente de codificação por voz para desenvolvedores. O usuário está ditando código ou descrevendo lógica de programação.

            REGRAS ESTRITAS:
            1. Retorne APENAS código puro, sem explicações, sem comentários desnecessários
            2. NUNCA use markdown (```) ou formatação de bloco
            3. NUNCA cumprimente, diga "olá", "aqui está", "claro" ou faça introduções
            4. NUNCA explique o que o código faz
            5. Remova filler words: "então", "tipo", "né", "assim", "bem", "ah", "hm", "uh"
            6. Interprete linguagem natural como código:
               - "função soma" → func soma()
               - "variável x igual a 5" → let x = 5
               - "se x maior que 10" → if x > 10
            7. Use a linguagem mencionada, ou Swift como padrão
            8. Siga convenções e boas práticas da linguagem
            """
            
        case .text:
            basePrompt = """
            Você é um assistente de transcrição inteligente. O usuário está ditando texto por voz.

            REGRAS ESTRITAS:
            1. Transcreva o áudio em texto limpo e bem formatado
            2. REMOVA completamente filler words: "então", "tipo", "né", "assim", "bem", "ah", "hm", "uh"
            3. NUNCA cumprimente ou diga "olá", "aqui está", "claro"
            4. Corrija gramática, pontuação e estrutura
            5. Mantenha o significado e intenção original
            6. Use parágrafos quando apropriado
            7. Retorne APENAS o texto final, sem explicações
            """
            
        case .uxDesign:
            basePrompt = """
            Você é um assistente especializado em UX Design. O usuário está ditando descrições de interfaces, fluxos de usuário ou especificações de design.

            REGRAS ESTRITAS:
            1. Formate o texto de forma clara e estruturada para documentação de UX
            2. Use bullet points quando apropriado
            3. Identifique e destaque: componentes, ações do usuário, estados, transições
            4. NUNCA cumprimente ou faça introduções
            5. Remova filler words
            6. Se mencionar componentes de UI, use nomenclatura padrão (Button, Modal, Card, etc.)
            7. Retorne texto formatado pronto para documentação
            8. Se for descrição de fluxo, organize em passos numerados
            """
        }
        
        var finalPrompt = basePrompt
        
        // Adicionar instruções de clareza
        if clarifyText {
            finalPrompt += """
            
            
            CLAREZA E ORGANIZAÇÃO:
            - Reorganize frases confusas para ficarem claras e lógicas
            - Corrija erros de concordância e gramática
            - Remova repetições desnecessárias
            - Estruture o texto de forma coesa
            - Se a fala estiver confusa, interprete a intenção e escreva de forma clara
            - Transforme ideias desorganizadas em texto bem estruturado
            """
        }
        
        // Adicionar tradução
        if translateToEnglish {
            finalPrompt += """
            
            
            IMPORTANTE - TRADUÇÃO:
            O usuário pode falar em português, mas você DEVE retornar o resultado em INGLÊS.
            Traduza todo o conteúdo para inglês de forma natural e profissional.
            """
        }
        
        return finalPrompt
    }
}
