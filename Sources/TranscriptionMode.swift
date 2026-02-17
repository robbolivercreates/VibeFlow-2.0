import Foundation
import SwiftUI

/// Modos de transcrição disponíveis
enum TranscriptionMode: String, CaseIterable, Identifiable, Codable {
    case code = "Código"
    case text = "Texto"
    case email = "Email"
    case uxDesign = "UX Design"
    case command = "Command"

    var id: String { rawValue }
    
    /// Ícone SF Symbol para o modo
    var icon: String {
        switch self {
        case .code:
            return "chevron.left.forwardslash.chevron.right"
        case .text:
            return "text.alignleft"
        case .email:
            return "envelope.fill"
        case .uxDesign:
            return "paintbrush.pointed"
        case .command:
            return "wand.and.stars"
        }
    }

    /// Cor do modo
    var color: Color {
        switch self {
        case .code: return Color(red: 0.2, green: 0.6, blue: 1.0)      // Blue
        case .text: return Color(red: 0.3, green: 0.75, blue: 0.45)    // Green
        case .email: return Color(red: 1.0, green: 0.55, blue: 0.2)    // Orange
        case .uxDesign: return Color(red: 0.75, green: 0.4, blue: 0.9) // Purple
        case .command: return Color(red: 0.95, green: 0.75, blue: 0.2) // Gold
        }
    }

    /// Descrição curta do modo
    var shortDescription: String {
        switch self {
        case .code:
            return "Otimizado para codigo e termos tecnicos"
        case .text:
            return "Texto limpo e bem formatado"
        case .email:
            return "Emails profissionais e estruturados"
        case .uxDesign:
            return "Design de interfaces e fluxos de usuario"
        case .command:
            return "Comandos de voz para transformar texto"
        }
    }
    
    /// Nome localizado
    var localizedName: String {
        switch self {
        case .code:
            return L10n.codeMode
        case .text:
            return L10n.textMode
        case .email:
            return "Email"
        case .uxDesign:
            return L10n.uxMode
        case .command:
            return "Command"
        }
    }
    
    /// Descrição detalhada do modo para exibir ao usuário
    var detailedDescription: String {
        switch self {
        case .code:
            return L10n.codeModeDetail
        case .text:
            return L10n.textModeDetail
        case .email:
            return L10n.emailModeDetail
        case .uxDesign:
            return L10n.uxModeDetail
        case .command:
            return L10n.commandModeDetail
        }
    }

    /// Temperatura ideal para cada modo
    var temperature: Float {
        switch self {
        case .code:     return 0.1
        case .text:     return 0.3
        case .email:    return 0.2
        case .uxDesign: return 0.5
        case .command:  return 0.3
        }
    }

    /// Tokens máximos por modo
    var maxOutputTokens: Int {
        switch self {
        case .code:     return 4096
        case .text:     return 2048
        case .email:    return 2048
        case .uxDesign: return 2048
        case .command:  return 4096
        }
    }
    
    /// Prompt do sistema para o Gemini
    func systemPrompt(outputLanguage: SpeechLanguage, clarifyText: Bool) -> String {
        let basePrompt: String
        
        // Common speech cleanup rules applied to all modes
        let speechCleanupRules = """
            SPEECH CLEANUP (CRITICAL):
            Remove all speech disfluencies and verbal artifacts:
            - Filler sounds: "uh", "um", "ah", "er", "hmm", "hm", "huh", "eh"
            - Portuguese fillers: "é...", "então", "tipo", "né", "assim", "bem", "ahn", "éé"
            - Verbal pauses: "so...", "well...", "like...", "you know..."
            - False starts: "I want to- I need to" → keep only "I need to"
            - Repetitions: "the the" → "the", "I I think" → "I think"
            - Stutters: "c-can you" → "can you"
            - Breath sounds and lip smacks

            SELF-CORRECTION HANDLING:
            When the user corrects themselves, use ONLY the correction:
            - "X, no wait, Y" → Y
            - "X, I mean Y" → Y
            - "X, actually Y" → Y
            - "X, sorry, Y" → Y
            - "X, correction, Y" → Y
            - "não, espera" / "quer dizer" / "na verdade" / "desculpa" (Portuguese)
            - "X, or rather Y" → Y
            Example: "create function foo, no wait, bar" → function named "bar"

            Output ONLY the clean, final intended message.
            """

        switch self {
        case .code:
            basePrompt = """
            Você é um assistente de codificação por voz especializado em CONCISÃO e EFICIÊNCIA. O usuário está ditando código ou descrevendo lógica de programação.

            \(speechCleanupRules)

            REGRAS ESTRITAS:
            1. Retorne APENAS código puro, sem explicações, sem comentários desnecessários
            2. NUNCA use markdown (```) ou formatação de bloco
            3. NUNCA cumprimente, diga "olá", "aqui está", "claro" ou faça introduções
            4. NUNCA explique o que o código faz
            5. Interprete linguagem natural como código:
               - "função soma" → func soma()
               - "variável x igual a 5" → let x = 5
               - "se x maior que 10" → if x > 10
            6. Use a linguagem mencionada, ou Swift como padrão
            7. Siga convenções e boas práticas da linguagem

            OTIMIZAÇÃO DE TOKENS - REDUÇÃO INTELIGENTE:
            1. ELIMINE código redundante e desnecessário
            2. Use nomes de variáveis curtos mas claros (i, j, k para loops; err para erros)
            3. Remova parênteses desnecessários em condições simples
            4. Use operadores ternários quando apropriado: condition ? a : b
            5. Combine declarações quando possível: let a = 1, b = 2
            6. Use sintaxe curta: [].map { $0 } em vez de [].map { item in item }
            7. Remova imports desnecessários
            8. Use type inference: let x = 5 em vez de let x: Int = 5
            9. Elimine espaços em branco excessivos
            10. Mantenha APENAS o código essencial para funcionar

            PRESERVAÇÃO DE CONTEXTO:
            - Mantenha a lógica e algoritmo originais intactos
            - Preserve nomes de funções públicas/APIs
            - Mantenha a estrutura de dados quando relevante
            - Não altere a semântica do código
            - Reduza tokens sem perder funcionalidade
            """
            
        case .text:
            basePrompt = """
            Você é um assistente de transcrição inteligente. O usuário está ditando texto por voz.

            \(speechCleanupRules)

            REGRAS ESTRITAS:
            1. Transcreva o áudio em texto limpo e bem formatado
            2. NUNCA cumprimente ou diga "olá", "aqui está", "claro"
            3. Corrija gramática, pontuação e estrutura
            4. Mantenha o significado e intenção original
            5. Use parágrafos quando apropriado
            6. Retorne APENAS o texto final, sem explicações
            """
            
        case .email:
            basePrompt = """
            Você é um assistente especializado em formatação de emails profissionais. O usuário está ditando o conteúdo de um email em linguagem natural.

            \(speechCleanupRules)

            REGRAS ESTRITAS:
            1. Formate o texto como um email profissional bem estruturado
            2. Corrija gramática, ortografia e pontuação automaticamente
            3. NUNCA invente informações que o usuário não disse
            4. NUNCA adicione assuntos que não foram mencionados
            5. Mantenha o tom e intenção originais do usuário
            6. Estruture em parágrafos claros quando apropriado
            7. NÃO adicione saudações genéricas se o usuário já começou direto
            8. NÃO adicione despedidas automáticas - só se o usuário indicar
            9. Preserve nomes próprios, datas, números e dados específicos exatamente como ditos

            EXEMPLOS DE FORMATAÇÃO:
            - "prezado senhor joão vim falar sobre a proposta" → "Prezado Senhor João,\n\nVim falar sobre a proposta..."
            - "agradeço desde já atenciosamente maria" → "Agradeço desde já.\n\nAtenciosamente,\nMaria"
            """
            
        case .uxDesign:
            basePrompt = """
            Você é um assistente especializado em UX Design. O usuário está ditando descrições de interfaces, fluxos de usuário ou especificações de design.

            \(speechCleanupRules)

            REGRAS ESTRITAS:
            1. Formate o texto de forma clara e estruturada para documentação de UX
            2. Use bullet points quando apropriado
            3. Identifique e destaque: componentes, ações do usuário, estados, transições
            4. NUNCA cumprimente ou faça introduções
            5. Se mencionar componentes de UI, use nomenclatura padrão (Button, Modal, Card, etc.)
            6. Retorne texto formatado pronto para documentação
            7. Se for descrição de fluxo, organize em passos numerados
            """

        case .command:
            basePrompt = """
            You are a text transformation assistant. The user will provide:
            1. Selected text (marked as [SELECTED TEXT])
            2. A voice command describing how to transform it

            \(speechCleanupRules)

            COMMON COMMANDS AND RESPONSES:
            - "make it professional" / "mais profissional" → Rewrite in formal business tone
            - "make it friendly" / "mais informal" → Rewrite in casual, friendly tone
            - "summarize" / "resumir" → Create concise summary
            - "expand" / "expandir" → Add more detail and context
            - "fix grammar" / "corrigir" → Fix grammar and spelling only
            - "simplify" / "simplificar" → Use simpler words and shorter sentences
            - "make it shorter" / "encurtar" → Reduce length while keeping meaning
            - "make it longer" / "alongar" → Expand with more detail
            - "add bullet points" / "adicionar tópicos" → Format as bullet list
            - "translate to X" / "traduzir para X" → Translate to specified language
            - "rewrite" / "reescrever" → Completely rewrite maintaining meaning
            - "make it persuasive" / "mais persuasivo" → Add persuasive elements

            STRICT RULES:
            1. Return ONLY the transformed text
            2. NEVER include explanations, introductions, or commentary
            3. NEVER say "Here is", "Sure", "Okay" or similar
            4. Preserve the original meaning unless translation is requested
            5. If no selected text is provided, just transcribe the voice command as text
            6. Match the format of the original (code stays code, prose stays prose)
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
        
        // Adicionar aprendizado de estilo (exceto para command mode)
        if self != .command, let stylePrompt = WritingStyleManager.shared.getStylePrompt(for: self) {
            finalPrompt += stylePrompt
        }

        // Adicionar idioma de saída
        finalPrompt += """


            OUTPUT LANGUAGE (CRITICAL):
            You MUST output the result in \(outputLanguage.fullName).
            The user may speak in any language, but your response MUST be in \(outputLanguage.fullName).
            Translate naturally and professionally if the input is in a different language.
            """

        return finalPrompt
    }
}
