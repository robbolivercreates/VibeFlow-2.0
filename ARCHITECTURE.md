# VibeFlow - Documentação de Arquitetura

## 📁 Estrutura do Projeto

```
VibeFlow/
├── Sources/
│   ├── VibeFlow/
│   │   ├── Managers/          # Gerenciadores de estado
│   │   │   ├── SettingsManager.swift      # Configurações do app
│   │   │   ├── HistoryManager.swift       # Histórico de transcrições
│   │   │   ├── SnippetsManager.swift      # Snippets de texto
│   │   │   ├── SoundManager.swift         # Efeitos sonoros
│   │   │   └── AnalyticsManager.swift     # Estatísticas de uso
│   │   │
│   │   ├── Views/             # Interfaces SwiftUI
│   │   │   ├── ContentView.swift          # View principal
│   │   │   ├── SetupWizardView.swift      # Wizard de onboarding
│   │   │   ├── SettingsView.swift         # Configurações
│   │   │   ├── HistoryView.swift          # Histórico
│   │   │   ├── SnippetsView.swift         # Gerenciador de snippets
│   │   │   ├── AnalyticsView.swift        # Estatísticas
│   │   │   └── LicenseActivationView.swift # Ativação de licença
│   │   │
│   │   └── (nenhum arquivo direto)
│   │
│   ├── VibeFlowApp.swift      # Entry point do app
│   ├── VibeFlowViewModel.swift # ViewModel principal
│   ├── ContentView.swift      # (antigo, pode remover)
│   ├── TranscriptionMode.swift # Modos de transcrição
│   ├── AudioRecorder.swift    # Gravação de áudio
│   ├── GeminiService.swift    # Integração com API
│   ├── ClipboardHelper.swift  # Helper de clipboard
│   ├── AppIcon.swift          # Gerador de ícone
│   ├── AppVersion.swift       # Versão do app
│   └── Localization.swift     # Strings localizadas
│
├── Distribution/              # Arquivos de distribuição
│   ├── generate_keys.py       # Script gerador de chaves
│   ├── create_dmg.sh          # Script criador de DMG
│   ├── output/                # DMGs gerados
│   └── LICENSING.md           # Estratégia de licenciamento
│
├── Scripts/
│   └── build.sh               # Script de build
│
├── Package.swift              # Dependências Swift
├── Info.plist                 # Configurações do app
└── README.md                  # Documentação
```

---

## 🏗️ Arquitetura Geral

### Padrão: MVVM (Model-View-ViewModel)

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    View     │────▶│  ViewModel  │────▶│    Model    │
│  (SwiftUI)  │◀────│ (Observable)│◀────│  (Dados)    │
└─────────────┘     └─────────────┘     └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   Manager   │
                    │  (Singleton)│
                    └─────────────┘
```

---

## 🔧 Componentes Principais

### 1. VibeFlowApp.swift
**Responsabilidade:** Ponto de entrada do app

```swift
@main
struct VibeFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
}

class AppDelegate: NSObject, NSApplicationDelegate {
    // Menu bar, janelas, atalhos globais
}
```

**Modificar quando:**
- Adicionar nova janela
- Mudar atalhos globais
- Adicionar menu items

---

### 2. VibeFlowViewModel.swift
**Responsabilidade:** Lógica de negócio central

**Propriedades publicadas:**
- `isRecording: Bool` - Estado de gravação
- `isProcessing: Bool` - Estado de processamento
- `selectedMode: TranscriptionMode` - Modo atual
- `audioLevel: CGFloat` - Nível do áudio para animação

**Métodos principais:**
- `toggleRecording()` - Inicia/para gravação
- `updateMode(_:)` - Muda modo de transcrição
- `reloadAPIKey()` - Recarrega configurações

**Modificar quando:**
- Adicionar novo estado global
- Mudar fluxo de gravação
- Adicionar novas features

---

### 3. SettingsManager.swift
**Responsabilidade:** Persistência de configurações

**Padrão:** Singleton com `@Published`

**Chaves armazenadas:**
```swift
apiKey: String                    // API Key do Gemini
onboardingCompleted: Bool         // Wizard foi visto
selectedMode: TranscriptionMode   // Modo padrão
enableSounds: Bool                // Sons ativados
enableHistory: Bool               // Histórico ativado
enableAutoPaste: Bool             // Auto-paste ativado
enableAutoClose: Bool             // Auto-close ativado
licenseKey: String                // Chave de licença
isLicensed: Bool                  // Licenciado?
shortcutRecordKey: String         // Atalho de gravação
shortcutToggleKey: String         // Atalho toggle janela
```

**Modificar quando:**
- Adicionar nova configuração
- Mudar comportamento de persistência

---

### 4. TranscriptionMode.swift
**Responsabilidade:** Definição dos modos de transcrição

```swift
enum TranscriptionMode: String, CaseIterable {
    case code = "Código"           // Para desenvolvedores
    case text = "Texto"            // Texto geral
    case email = "Email"           // Formatação de email
    case uxDesign = "UX Design"    // Para designers
}
```

**Propriedades por modo:**
- `temperature: Float` - Criatividade da IA (0.1 a 0.5)
- `maxOutputTokens: Int` - Limite de tokens
- `systemPrompt(...)` - Prompt do sistema para Gemini

**Modificar quando:**
- Adicionar novo modo
- Ajustar prompts
- Mudar temperatura/tokens

---

### 5. AudioRecorder.swift
**Responsabilidade:** Gravação de áudio do microfone

**Features:**
- Permissão de microfone
- Medição de nível de áudio (para animação)
- Detecção de fala (não cola se silêncio)

**Modificar quando:**
- Mudar qualidade de áudio
- Ajustar detecção de fala
- Adicionar filtros de áudio

---

### 6. GeminiService.swift
**Responsabilidade:** Comunicação com API Google Gemini

**Fluxo:**
1. Recebe audioData
2. Converte para formato Gemini
3. Envia com systemPrompt do modo atual
4. Retorna texto transcrito

**Modificar quando:**
- Mudar modelo (atual: gemini-2.5-flash)
- Ajustar parâmetros de geração
- Adicionar retry logic

---

## 🎨 Fluxo de Dados

### Gravação e Transcrição:

```
Usuário segura ⌥⌘
       │
       ▼
AppDelegate detecta atalho
       │
       ▼
VibeFlowViewModel.toggleRecording()
       │
       ▼
AudioRecorder.startRecording()
       │
       ▼
[Gravação em progresso...]
       │
       ▼
Usuário solta ⌥⌘
       │
       ▼
AudioRecorder.stopRecording()
       │
       ▼
GeminiService.transcribeAudio(audioData)
       │
       ▼
[IA processa...]
       │
       ▼
ClipboardHelper.copyAndPaste(texto)
       │
       ▼
AnalyticsManager.recordTranscription()
       │
       ▼
HistoryManager.add(texto)
```

---

## 🔐 Sistema de Licenciamento

### Chave Mestre:
```
VIBE-MASTER-2024-PRO
```
- Ativa qualquer instalação
- Uso pessoal do desenvolvedor

### Chaves de Venda:
```
VIBE-XXXX-XXXX-XXXX
```
- Formato: 4 grupos de 4 caracteres
- Caracteres válidos: A-Z (sem O,I) + 2-9 (sem 0,1)
- Geradas por: Distribution/generate_keys.py

### Fluxo de Ativação:
```
Primeiro uso
     │
     ▼
Mostra LicenseActivationView
     │
     ▼
Usuário digita key
     │
     ▼
Validação local (formato)
     │
     ▼
[Futuro: validação online]
     │
     ▼
Salva em SettingsManager
     │
     ▼
Mostra wizard de onboarding
```

---

## 📊 Analytics

### Dados coletados:
- Total de transcrições
- Total de caracteres
- Tempo economizado (calculado)
- Estatísticas mensais

### Cálculo de tempo:
```
Fórmula: (caracteres / 5) / 40 WPM

Exemplo: 200 caracteres
- 200 / 5 = 40 palavras
- 40 / 40 WPM = 1 minuto economizado
```

---

## 🚀 Build e Distribuição

### Comandos:
```bash
# Build de desenvolvimento
swift build

# Build de release
swift build -c release

# Criar app bundle
./Scripts/build.sh

# Criar DMG
cd Distribution
./create_dmg.sh
```

### Saídas:
- `.build/release/VibeFlow` - Binário
- `VibeFlow.app` - App bundle
- `Distribution/output/VibeFlow-2.3.0.dmg` - DMG para distribuição

---

## 📝 Notificações

### NotificationCenter:
- `.modeChanged` - Modo alterado
- `.transcriptionComplete` - Transcrição finalizada
- `.recordingCancelled` - Gravação cancelada (sem fala)
- `.showWizardAfterActivation` - Mostrar wizard após ativação
- `.shortcutChanged` - Atalho alterado

---

## 🛠️ Modificações Comuns

### Adicionar novo modo de transcrição:
1. Editar `TranscriptionMode.swift`
2. Adicionar case ao enum
3. Definir ícone, cor, temperatura
4. Criar systemPrompt
5. Adicionar cor em `ContentView.swift`
6. Adicionar cor em `HistoryView.swift`

### Adicionar nova configuração:
1. Editar `SettingsManager.swift`
2. Adicionar key em `Keys` enum
3. Adicionar `@Published var`
4. Inicializar no `init()`
5. Usar em `SettingsView.swift`

### Adicionar nova view:
1. Criar arquivo em `Sources/VibeFlow/Views/`
2. Criar janela em `VibeFlowApp.swift`
3. Adicionar menu item em `updateMenu()`

---

## 📚 Dependências

### Package.swift:
```swift
GoogleGenerativeAI  // API Gemini
```

### Frameworks nativos:
- SwiftUI - Interface
- AVFoundation - Áudio
- AppKit - macOS específico
- Combine - Reactive

---

## 🔗 Links Úteis

- Repositório: https://github.com/robbolivercreates/VibeFlow
- API Gemini: https://ai.google.dev/
- Documentação Tauri (futuro Windows): https://tauri.app/

---

**Última atualização:** 2026-02-17
**Versão:** 2.3.0
**Autor:** Robson Oliveira
