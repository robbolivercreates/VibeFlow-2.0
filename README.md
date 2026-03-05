# VibeFlow 2.1 🎙️

Transforme sua voz em código e texto com inteligência artificial.

![VibeFlow Screenshot](screenshot.png)

## ✨ Features

- 🎙️ **Gravação por voz** - Segure ⌥⌘ e fale naturalmente
- 🤖 **Google Gemini AI** - Transcrição inteligente e precisa
- 📋 **Auto-paste** - Cola automaticamente no app ativo
- 🎯 **4 Modos**: Code, Texto, Email, UX Design
- 💾 **Histórico** - Últimas 50 transcrições salvas
- 📝 **Snippets** - Atalhos de texto expansíveis
- 🔊 **Efeitos sonoros** - Feedback auditivo
- 🧙 **Setup Wizard** - Onboarding guiado
- 🌍 **Bilingue** - Português e Inglês

## 🚀 Instalação

### Download
Baixe a última versão em [Releases](https://github.com/robbolivercreates/VibeFlow/releases)

### Requisitos
- macOS 13.0+
- API Key do Google Gemini (gratuita)

### Setup
1. Baixe e arraste `VibeFlow.app` para `/Applications`
2. Abra o app e siga o wizard de configuração
3. Configure sua API Key do Gemini
4. Conceda permissões de Microfone e Acessibilidade

## 🎮 Como usar

| Atalho | Ação |
|--------|------|
| ⌥⌘ (segure) | Gravar |
| ⌘⇧V | Mostrar/esconder janela |
| ⌘, | Configurações |
| ⌘Y | Histórico |

## 💡 Modos de Transcrição

### 🔵 Code
Para desenvolvedores. Converte linguagem natural em código:
- "função soma" → `func soma()`
- "se x maior que 10" → `if x > 10`
- Otimizado para reduzir tokens mantendo contexto

### 🟢 Texto
Para documentos gerais. Remove filler words e corrige gramática.

### 🟠 Email
Formata como email profissional:
- Corrige ortografia automaticamente
- Mantém tom profissional
- Não inventa conteúdo

### 🟣 UX Design
Para designers. Estrutura descrições de interface e fluxos.

## ⚙️ Configuração

### Obter API Key do Gemini
1. Acesse [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Clique em "Create API Key"
3. Copie e cole no VibeFlow

**Nota:** A API key é gratuita com limite generoso de requisições.

## 🛠️ Desenvolvimento

### Build
```bash
swift build -c release
./Scripts/build.sh
```

### Tecnologias
- Swift 5.9+
- SwiftUI
- Google Generative AI SDK
- AVFoundation

## 📄 Licença

MIT License - veja [LICENSE](LICENSE) para detalhes

## 🤝 Contribuição

Contribuições são bem-vindas! Abra uma issue ou pull request.

---

**Feito com ❤️ por [Robson Oliveira](https://github.com/robbolivercreates)**
