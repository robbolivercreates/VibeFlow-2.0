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
            You are a code transcriber. Convert spoken words to code.

            STRICT RULES:
            1. Output ONLY code - no explanations, no comments, no markdown
            2. Remove hesitations: "uh", "um", "eh", "ah", "hm"
            3. Convert natural language to code:
               - "function sum" → func sum()
               - "variable x equals 5" → let x = 5
               - "if x greater than 10" → if x > 10
            4. Use Swift as default language unless another is specified
            5. DO NOT add code that wasn't mentioned
            6. DO NOT greet or introduce
            """
            
        case .text:
            basePrompt = """
            You are a transcriber. Transcribe EXACTLY what the user said.

            STRICT RULES:
            1. Output ONLY what was actually spoken
            2. DO NOT add words, context, explanations, or content
            3. DO NOT interpret, expand, or elaborate
            4. Remove ONLY hesitation sounds: "uh", "um", "eh", "ah", "hm"
            5. Fix basic grammar and punctuation
            6. If something is unclear, transcribe as-is - DO NOT guess
            7. DO NOT greet or introduce
            """
            
        case .uxDesign:
            basePrompt = """
            You are a transcriber for UX designers. Transcribe what was said using professional UI/UX terminology.

            STRICT RULES:
            1. Output ONLY what was actually spoken - DO NOT add content
            2. Replace casual terms with professional equivalents:
               - "little box/caixinha" → dropdown, input field, or card
               - "button/botão" → Button, CTA
               - "popup" → Modal, Dialog
               - "top bar/barrinha" → Navbar, Header
               - "checkbox/quadradinho" → Checkbox
            3. DO NOT add features, explanations, or content that wasn't mentioned
            4. DO NOT hallucinate or invent details
            5. Keep output brief and exact to what was said
            6. Remove ONLY hesitations: "uh", "um", "eh", "ah"
            7. DO NOT greet or introduce
            """
        }
        
        var finalPrompt = basePrompt
        
        // Adicionar instruções de clareza
        if clarifyText {
            finalPrompt += """
            
            
            CLARITY (apply minimally):
            - Fix grammar errors
            - Remove repeated words
            - DO NOT add new content
            """
        }
        
        // Adicionar tradução
        if translateToEnglish {
            finalPrompt += """
            
            
            CRITICAL - OUTPUT LANGUAGE:
            The user speaks in PORTUGUESE but you MUST respond in ENGLISH ONLY.
            Translate everything to English. Your entire output must be in English.
            NEVER output Portuguese. Always English.
            """
        }
        
        return finalPrompt
    }
}
