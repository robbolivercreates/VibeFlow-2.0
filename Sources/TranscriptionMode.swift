import Foundation
import SwiftUI

/// Modos de transcrição disponíveis
enum TranscriptionMode: String, CaseIterable, Identifiable, Codable {
    case text = "Texto"
    case chat = "Chat"
    case code = "Código"
    case vibeCoder = "Vibe Coder"
    case email = "Email"
    case formal = "Formal"
    case social = "Social"
    case xTweet = "X"
    case summary = "Resumo"
    case topics = "Tópicos"
    case meeting = "Reunião"
    case uxDesign = "UX Design"
    case translation = "Tradução"
    case creative = "Criativo"
    case custom = "Meu Modo"

    var id: String { rawValue }

    /// Voice keywords that trigger this mode via wake word ("Vox, <keyword>")
    /// Supports Portuguese, English and common speech variations
    var voiceAliases: [String] {
        switch self {
        case .text:        return ["texto", "text", "transcrição", "transcricao", "transcription", "normal"]
        case .chat:        return ["chat", "conversa", "conversation", "reply"]
        case .code:        return ["código", "codigo", "code", "programação", "programacao", "programming"]
        case .vibeCoder:   return ["vibe coder", "vibe", "vibe coding", "vibecoder"]
        case .email:       return ["email", "e-mail", "emails", "mensagem", "message"]
        case .formal:      return ["formal", "profissional", "professional", "corporativo", "corporate"]
        case .social:      return ["social", "post", "instagram", "redes sociais"]
        case .xTweet:      return ["tweet", "x", "twitter"]
        case .summary:     return ["resumo", "summary", "resumir", "summarize", "sintetizar"]
        case .topics:      return ["tópicos", "topicos", "topics", "bullet points", "bullets", "lista", "list"]
        case .meeting:     return ["reunião", "reuniao", "meeting", "ata", "minutes"]
        case .uxDesign:    return ["ux", "ux design", "design", "ui", "interface"]
        case .translation: return []  // Translation mode is triggered via UI button, not voice
        case .creative:    return ["criativo", "creative", "criatividade", "creativity", "storytelling"]
        case .custom:      return ["meu modo", "custom", "personalizado", "personal"]
        }
    }

    /// Lowercase English name sent to the edge function (must match FREE_MODES on server)
    var apiName: String {
        switch self {
        case .text:        return "text"
        case .chat:        return "chat"
        case .code:        return "code"
        case .vibeCoder:   return "vibe_coder"
        case .email:       return "email"
        case .formal:      return "formal"
        case .social:      return "social"
        case .xTweet:      return "x"
        case .summary:     return "summary"
        case .topics:      return "topics"
        case .meeting:     return "meeting"
        case .uxDesign:    return "ux_design"
        case .translation: return "translation"
        case .creative:    return "creative"
        case .custom:      return "custom"
        }
    }

    /// Ícone SF Symbol para o modo
    var icon: String {
        switch self {
        case .text:        return "text.alignleft"
        case .chat:        return "bubble.fill"
        case .code:        return "chevron.left.forwardslash.chevron.right"
        case .vibeCoder:   return "wand.and.stars"
        case .email:       return "envelope.fill"
        case .formal:      return "building.2.fill"
        case .social:      return "megaphone.fill"
        case .xTweet:      return "at"
        case .summary:     return "doc.text"
        case .topics:      return "list.bullet"
        case .meeting:     return "person.3.fill"
        case .uxDesign:    return "paintbrush.pointed"
        case .translation: return "bubble.left.and.bubble.right.fill"
        case .creative:    return "paintpalette.fill"
        case .custom:      return "slider.horizontal.3"
        }
    }

    /// Cor do modo
    var color: Color {
        switch self {
        case .text:        return Color(red: 0.3, green: 0.75, blue: 0.45)    // Green
        case .chat:        return Color(red: 0.35, green: 0.82, blue: 0.65)   // Mint
        case .code:        return Color(red: 0.2, green: 0.6, blue: 1.0)      // Blue
        case .vibeCoder:   return Color(red: 0.0, green: 0.8, blue: 0.85)     // Cyan
        case .email:       return Color(red: 1.0, green: 0.55, blue: 0.2)     // Orange
        case .formal:      return Color(red: 0.25, green: 0.35, blue: 0.65)   // Navy
        case .social:      return Color(red: 0.9, green: 0.3, blue: 0.55)     // Pink
        case .xTweet:      return Color(red: 0.45, green: 0.65, blue: 0.95)   // Sky blue
        case .summary:     return Color(red: 0.45, green: 0.35, blue: 0.85)   // Indigo
        case .topics:      return Color(red: 0.2, green: 0.7, blue: 0.7)      // Teal
        case .meeting:     return Color(red: 0.5, green: 0.5, blue: 0.7)      // Slate
        case .uxDesign:    return Color(red: 0.75, green: 0.4, blue: 0.9)     // Purple
        case .translation: return Color(red: 0.98, green: 0.2, blue: 0.4)     // Rose
        case .creative:    return Color(red: 0.95, green: 0.45, blue: 0.35)   // Coral
        case .custom:      return Color(red: 0.6, green: 0.6, blue: 0.65)     // Silver
        }
    }

    /// Descrição curta do modo
    var shortDescription: String {
        switch self {
        case .text:        return L10n.textModeShort
        case .chat:        return L10n.chatModeShort
        case .code:        return L10n.codeModeShort
        case .vibeCoder:   return L10n.vibeCoderModeShort
        case .email:       return L10n.emailModeShort
        case .formal:      return L10n.formalModeShort
        case .social:      return L10n.socialModeShort
        case .xTweet:      return L10n.xTweetModeShort
        case .summary:     return L10n.summaryModeShort
        case .topics:      return L10n.topicsModeShort
        case .meeting:     return L10n.meetingModeShort
        case .uxDesign:    return L10n.uxModeShort
        case .translation: return L10n.translationModeShort
        case .creative:    return L10n.creativeModeShort
        case .custom:      return L10n.customModeShort
        }
    }

    /// Nome localizado
    var localizedName: String {
        switch self {
        case .text:        return L10n.textMode
        case .chat:        return "Chat"
        case .code:        return L10n.codeMode
        case .vibeCoder:   return "Vibe Coder"
        case .email:       return "Email"
        case .formal:      return L10n.formalMode
        case .social:      return "Social"
        case .xTweet:      return "X"
        case .summary:     return L10n.summaryMode
        case .topics:      return L10n.topicsMode
        case .meeting:     return L10n.meetingMode
        case .uxDesign:    return L10n.uxMode
        case .translation: return L10n.translationMode ?? "Tradução"
        case .creative:    return L10n.creativeMode
        case .custom:      return L10n.customMode
        }
    }

    /// Descrição detalhada do modo para exibir ao usuário
    var detailedDescription: String {
        switch self {
        case .text:        return L10n.textModeDetail
        case .chat:        return L10n.chatModeDetail
        case .code:        return L10n.codeModeDetail
        case .vibeCoder:   return L10n.vibeCoderModeDetail
        case .email:       return L10n.emailModeDetail
        case .formal:      return L10n.formalModeDetail
        case .social:      return L10n.socialModeDetail
        case .xTweet:      return L10n.xTweetModeDetail
        case .summary:     return L10n.summaryModeDetail
        case .topics:      return L10n.topicsModeDetail
        case .meeting:     return L10n.meetingModeDetail
        case .uxDesign:    return L10n.uxModeDetail
        case .translation: return L10n.translationModeDetail ?? "Traduz automaticamente para o idioma de saída."
        case .creative:    return L10n.creativeModeDetail
        case .custom:      return L10n.customModeDetail
        }
    }

    /// Temperatura ideal para cada modo
    var temperature: Float {
        switch self {
        case .text:        return 0.3
        case .chat:        return 0.4
        case .code:        return 0.1
        case .vibeCoder:   return 0.3
        case .email:       return 0.2
        case .formal:      return 0.2
        case .social:      return 0.5
        case .xTweet:      return 0.5
        case .summary:     return 0.3
        case .topics:      return 0.2
        case .meeting:     return 0.3
        case .uxDesign:    return 0.5
        case .translation: return 0.2
        case .creative:    return 0.7
        case .custom:      return 0.4
        }
    }

    /// Tokens máximos por modo
    var maxOutputTokens: Int {
        switch self {
        case .code:        return 4096
        case .translation: return 4096
        case .xTweet:      return 512
        case .vibeCoder:   return 1024
        default:           return 2048
        }
    }

    /// Thinking level for Gemini 3 models (minimal, low, medium, high)
    /// Controls reasoning depth: higher = better quality but slower/costlier
    var thinkingLevel: String {
        switch self {
        case .text:        return "minimal"   // Fast transcription
        case .chat:        return "minimal"   // Quick casual messages
        case .social:      return "minimal"   // Quick posts
        case .xTweet:      return "minimal"   // Short, fast
        case .email:       return "low"       // Some structure needed
        case .formal:      return "low"       // Some formatting needed
        case .translation: return "low"       // Straightforward task
        case .summary:     return "low"       // Condensing, not complex
        case .topics:      return "low"       // List extraction
        case .meeting:     return "low"       // Structured extraction
        case .creative:    return "medium"    // Benefits from reasoning
        case .uxDesign:    return "medium"    // Structural thinking
        case .code:        return "high"      // Full reasoning for code
        case .vibeCoder:   return "high"      // Full reasoning for planning
        case .custom:      return "low"       // Default balanced
        }
    }

    /// Prompt do sistema para o Gemini
    func systemPrompt(outputLanguage: SpeechLanguage, clarifyText: Bool, wakeWord: String = "Vox") -> String {
        let basePrompt: String

        // Compact speech cleanup rules (~60 tokens instead of ~200)
        let speechCleanupRules = """
            SPEECH CLEANUP:
            - Remove fillers: "uh", "um", "ah", "é...", "tipo", "né", "assim", "hm"
            - Remove false starts and stutters, keep only final version
            - Self-corrections ("X, no wait, Y" / "X, quer dizer, Y") → keep only Y
            - PLAIN TEXT ONLY: no markdown, no asterisks, no code fences, no headers
            - Output ONLY the clean, final text
            """

        switch self {
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

        case .chat:
            basePrompt = """
            Transcrição para mensagens rápidas de chat.

            \(speechCleanupRules)

            REGRAS:
            1. Curto e natural, como WhatsApp ou Slack
            2. Mantenha o tom casual, NÃO formalize
            3. NÃO corrija gírias intencionais
            4. Use pontuação normal (vírgulas, pontos) para clareza
            5. APENAS a mensagem pronta para enviar
            """

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
            8. Use type inference, sintaxe curta, elimine redundância
            """

        case .vibeCoder:
            basePrompt = """
            Você é um assistente que extrai a ESSÊNCIA do que o usuário comunicou, preservando a intenção original.

            \(speechCleanupRules)

            REGRAS DE INTENÇÃO (CRÍTICO):
            - Se o usuário fez uma PERGUNTA → reformule como pergunta clara e direta
              Exemplo: "como eu posso fazer isso funcionar?" → "Como fazer isso funcionar?"
            - Se o usuário deu uma INSTRUÇÃO ou PEDIDO → reformule como instrução concisa
              Exemplo: "eu quero que você mude o botão pra azul" → "Mude o botão para azul"
            - Se o usuário fez uma OBSERVAÇÃO → mantenha como observação
              Exemplo: "isso tá quebrando quando abre" → "Isso quebra na abertura"
            - NUNCA converta uma pergunta em um comando imperativo
            - NUNCA converta uma observação em uma instrução

            REGRAS GERAIS:
            1. Remova repetições, explicações e contexto desnecessário
            2. Mantenha TODOS os termos técnicos e requisitos específicos
            3. Preserve direções (posição, local, cor, tamanho, nome de arquivo)
            4. Use a ÚLTIMA correção como decisão final
            5. Frase curta e direta, pronta para colar em um AI assistant
            6. APENAS a essência, sem prefácios nem explicações
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
            """

        case .formal:
            basePrompt = """
            Transforme a fala em texto formal e profissional.

            \(speechCleanupRules)

            REGRAS:
            1. Tom FORMAL e CORPORATIVO
            2. "a gente" → "nós", "pra" → "para", "tá" → "está"
            3. Conectivos formais: "portanto", "ademais", "conforme"
            4. Parágrafos bem organizados
            5. Mantenha o significado original intacto
            6. APENAS o texto formal
            """

        case .social:
            basePrompt = """
            Transforme em post social engajante (IMC: Impact, Method, Call).

            \(speechCleanupRules)

            REGRAS:
            1. Comece com pergunta forte ou frase de impacto
            2. Conteúdo claro em frases curtas, uma ideia por linha
            3. Feche com convite ao engajamento
            4. Máximo 2 emojis estratégicos. Sem hashtags
            5. APENAS o post final
            """

        case .xTweet:
            basePrompt = """
            Transforme em tweet de MÁXIMO 280 caracteres.

            \(speechCleanupRules)

            REGRAS:
            1. Hook forte + valor em 1-2 frases + fechamento sutil
            2. Direto, punchy, sem enrolação
            3. Máximo 1 emoji ou nenhum. Sem hashtags
            4. APENAS o tweet
            """

        case .summary:
            basePrompt = """
            Crie um RESUMO conciso do que foi dito.

            \(speechCleanupRules)

            REGRAS:
            1. Reduza para 20-30% do conteúdo original
            2. APENAS pontos essenciais e conclusões
            3. Frases curtas e objetivas, máximo 2-3 parágrafos
            4. Priorize: decisões, números, datas, ações
            5. NUNCA adicione informações não ditas
            6. Retorne direto o resumo, sem "Resumo:" ou similar
            """

        case .topics:
            basePrompt = """
            Transforme em lista organizada com bullet points.

            \(speechCleanupRules)

            REGRAS:
            1. Use "•" como marcador principal
            2. Um tópico por ideia/item mencionado
            3. Frases curtas e diretas
            4. Sub-itens com "  ◦" (indentado)
            5. Comece direto nos tópicos, sem título
            6. APENAS a lista
            """

        case .meeting:
            basePrompt = """
            Organize como ATA DE REUNIÃO estruturada.

            \(speechCleanupRules)

            FORMATO:
            PARTICIPANTES: (se mencionados)
            ASSUNTOS DISCUTIDOS:
            • [tópico]
            DECISÕES:
            • [decisão]
            AÇÕES / PRÓXIMOS PASSOS:
            • [ação] — Responsável: [nome se mencionado]

            REGRAS:
            1. Omita seções sem informação
            2. Priorize DECISÕES e AÇÕES
            3. NUNCA invente dados não mencionados
            4. Frases curtas e objetivas
            """

        case .uxDesign:
            basePrompt = """
            Você é um assistente especializado em UX Design. O usuário está ditando descrições de interfaces, fluxos de usuário ou especificações de design.

            \(speechCleanupRules)

            REGRAS ESTRITAS:
            1. Formate o texto de forma clara e estruturada para documentação de UX
            2. Use "•" para listas de itens e números para passos de fluxo
            3. Identifique componentes, ações do usuário, estados e transições — liste-os claramente sem usar asteriscos
            4. NUNCA cumprimente ou faça introduções
            5. Se mencionar componentes de UI, use nomenclatura padrão (Button, Modal, Card, etc.)
            6. Retorne texto em PLAIN TEXT, pronto para colar em qualquer ferramenta
            7. Para ênfase, use CAPS ao invés de asteriscos ou formatação markdown
            8. Se for descrição de fluxo, organize em passos numerados (1. 2. 3.)
            """

        case .translation:
            basePrompt = """
            Você é um tradutor simultâneo nativo e especialista em transcrição multilíngue.
            O usuário vai falar em QUALQUER idioma (você deve detectar o idioma falado automaticamente).
            A sua tarefa é transcrever e traduzir o que foi dito EXATAMENTE para o idioma de saída.

            \(speechCleanupRules)

            REGRAS ESTRITAS DE TRADUÇÃO:
            1. Traduza o áudio capturado direta e precisamente para o idioma de destino.
            2. NÃO forneça a transcrição original antes da tradução. Apenas o resultado final.
            3. A tradução deve soar natural, como se pensada no idioma de destino.
            4. Se o usuário já estiver falando no idioma de destino, transcreva normalmente corrigindo pequenos erros.
            5. NUNCA diga "Aqui está", "Tradução:", "Olá" ou explique o que fez. Retorne APENAS a tradução.
            6. Mantenha os mesmos parágrafos e o tom original do locutor.
            """

        case .creative:
            basePrompt = """
            Transforme a fala em texto CRIATIVO e envolvente.

            \(speechCleanupRules)

            REGRAS:
            1. Linguagem rica, descritiva e narrativa
            2. Ritmo e fluidez, figuras de linguagem quando natural
            3. Mantenha a essência e mensagem original
            4. Parágrafos com boa cadência de leitura
            5. APENAS o texto criativo
            """

        case .custom:
            let userInstruction = SettingsManager.shared.customModePrompt
            basePrompt = """
            Você é um assistente de transcrição inteligente.

            \(speechCleanupRules)

            REGRAS BASE:
            1. NUNCA cumprimente ou faça introduções
            2. Retorne APENAS o resultado final
            3. Mantenha o significado original

            INSTRUÇÃO DO USUÁRIO:
            \(userInstruction.isEmpty ? "Transcreva o áudio de forma limpa e organizada." : userInstruction)
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

        // Adicionar aprendizado de estilo (exceto para custom e vibeCoder)
        if self != .custom && self != .vibeCoder,
           let stylePrompt = WritingStyleManager.shared.getStylePrompt(for: self) {
            finalPrompt += stylePrompt
        }

        // Adicionar dicionário personalizado do usuário (correções de palavras e termos proibidos)
        if let dictPrompt = CustomDictionaryManager.shared.getDictionaryPrompt() {
            finalPrompt += dictPrompt
        }

        // Adicionar idioma de saída
        finalPrompt += """

            OUTPUT LANGUAGE (CRITICAL):
            You MUST output the result in \(outputLanguage.fullName).
            The user may speak in any language, but your response MUST be in \(outputLanguage.fullName).
            Translate naturally and professionally if the input is in a different language.
            """

        // ── Wake word passthrough (MUST be the very last rule, highest priority) ──
        // If the audio starts with the wake word, Gemini must NOT apply mode processing.
        // It must return the raw transcription verbatim so the app can route the command.
        let base = wakeWord.lowercased()
        let wakeVariants = [base, "fox", "box", "vocs", "voks", "boks", "voqs", "hawks", "blocks", "bos", "vos", "ei vox", "hey vox", "hey fox", "hey box", "a vox", "hey vocs"]
        _ = wakeVariants // variants still used for local matching in app
        finalPrompt += """


            WAKE WORD OVERRIDE (HIGHEST PRIORITY):
            If audio starts with "Vox" (or mishearings: "fox", "box", "vocs", "voks", "boks"),
            return the raw transcription EXACTLY as spoken. Skip ALL other rules.
            Do NOT translate or format wake word commands.
            Example: "Vox, email" → return exactly "Vox, email".
            """

        return finalPrompt
    }
}
