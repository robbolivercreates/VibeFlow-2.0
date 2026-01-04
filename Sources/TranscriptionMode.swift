import Foundation

/// Modos de transcrição disponíveis
enum TranscriptionMode: String, CaseIterable, Identifiable, Codable {
    case code = "Código"
    case text = "Texto"
    case uxDesign = "UX Design"
    case email = "Email"
    
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
        case .email:
            return "envelope"
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
        case .email:
            return L10n.emailMode
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
        case .email:
            return L10n.emailMode
        }
    }
    
    /// Prompt do sistema para o Gemini
    func systemPrompt(translateToEnglish: Bool, clarifyText: Bool) -> String {
        let basePrompt: String
        
        switch self {
        case .code:
            basePrompt = """
            CODE MODE
            STRICT RULES:
            1. Output ONLY code. No explanations, no comments, no markdown.
            2. Remove hesitation sounds and pauses:
               "uh", "um", "eh", "ah", "hm", "hã", elongated sounds, pauses.
            3. Convert natural language into code ONLY when explicitly spoken.
            4. Do NOT infer parameters, types, return values, logic, or structure.
            5. Use Swift as the default language unless another language is explicitly mentioned.
            6. Convert spoken symbols explicitly:
               - "open brace" -> {
               - "close brace" -> }
               - "open parenthesis" -> (
               - "close parenthesis" -> )
            7. Do NOT add code that was not mentioned.
            8. If the spoken input is insufficient to produce valid code, output NOTHING.
            9. Do NOT greet or introduce.
            """
            
        case .text:
            basePrompt = """
            TEXT MODE
            STRICT RULES:
            1. Output ONLY what was actually spoken.
            2. Remove hesitation sounds and pauses:
               "uh", "um", "eh", "ah", "hm", "hã", elongated sounds.
            3. Fix ONLY punctuation and capitalization.
            4. Do NOT rephrase, restructure, interpret, or expand.
            5. Do NOT add context, explanations, or missing words.
            6. If something is unclear, transcribe it as-is. Do NOT guess.
            7. Preserve the original language.
            8. Do NOT greet or introduce.
            """
            
        case .uxDesign:
            basePrompt = """
            You are a professional UX/UI designer writing documentation.
            The user will describe interfaces, features, or flows in casual language.
            Your job is to REWRITE their description using professional UX/UI terminology.

            STRICT RULES:
            1. REWRITE the content - do NOT transcribe literally.
            2. Write as if YOU are the UX designer documenting the interface.
            3. Use professional terms:
               - "caixinha/box" → input field, dropdown, card, container
               - "botão/button" → CTA, action button, primary button
               - "popup" → modal, dialog, overlay
               - "barrinha/bar" → navbar, header, toolbar, sidebar
               - "quadradinho" → checkbox, toggle, radio button
               - "tela/screen" → view, page, screen, interface
               - "lista" → list view, table, data grid
            4. Remove hesitations: "uh", "um", "eh", "ah", "hm", "hã", "tipo", "assim".
            5. Output ONLY the professional description.
            6. Do NOT say "I will act as..." or "As a UX designer...".
            7. Do NOT add features that weren't mentioned.
            8. Write in the SAME language as the user (Portuguese or English).
            9. Do NOT greet or introduce yourself.

            EXAMPLE:
            User says: "Eu quero uma caixinha onde a pessoa digita o email e um botãozinho do lado"
            You output: "Input field for email with adjacent action button"
            """
            
        case .email:
            basePrompt = """
            New Email mode
            You are an email transcriber and editor.

            STRICT RULES:
            1. Detect the language automatically (English or Portuguese).
            2. Do NOT translate. Keep the original language.
            3. Remove hesitation sounds and pauses:
               "uh", "um", "eh", "ah", "hm", "hã".
            4. Rewrite the text as a clear, simple, and natural email.
            5. Use simple, accessible words.
            6. Short sentences. Direct structure.
            7. Fix grammar, spelling, and punctuation ONLY.
            8. Do NOT add information, tone, or intent that was not spoken.
            9. Do NOT make the email formal unless it was clearly spoken as formal.
            10. Output ONLY the email text.
            11. Do NOT greet or introduce.
            """
        }
        
        var finalPrompt = basePrompt
        
        // Adicionar instruções de clareza (apenas se não for modo Email, pois Email já inclui clareza)
        if clarifyText && self != .email {
            finalPrompt += """
            
            
            CLARITY (apply minimally):
            - Fix grammar errors
            - Remove repeated words
            - DO NOT add new content
            """
        }
        
        // Adicionar tradução (apenas se não for modo Email, pois Email deve preservar o idioma original)
        if translateToEnglish && self != .email {
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
