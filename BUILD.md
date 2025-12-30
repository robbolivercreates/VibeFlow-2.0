# Instruções de Build - Vibe Flow

## Pré-requisitos

1. **Xcode 15+** (com Swift 5.9+)
2. **macOS 13.0+** (Ventura ou superior)
3. **API Key do Google Gemini** - Obtenha em: https://makersuite.google.com/app/apikey

## Build via Xcode

1. Abra o projeto:
   ```bash
   open Package.swift
   ```

2. No Xcode:
   - Selecione o target `VibeFlow`
   - Escolha "My Mac" como destino
   - Pressione `Cmd+B` para compilar

3. Execute o app:
   - Pressione `Cmd+R` ou clique em Run

## Build via Terminal

```bash
swift build -c release
```

O executável estará em: `.build/release/VibeFlow`

## Configuração Inicial

1. **Primeira execução:**
   - O app aparecerá na barra de menu (ícone de microfone)
   - Clique no ícone e selecione "Configurações..."
   - Cole sua API Key do Google Gemini
   - Clique em "Salvar"

2. **Permissões necessárias:**
   - **Microfone**: Sistema > Privacidade e Segurança > Microfone
   - **Acessibilidade**: Sistema > Privacidade e Segurança > Acessibilidade
     - Necessário para simular Cmd+V automaticamente

## Uso

1. **Abrir janela:**
   - Clique no ícone na barra de menu, OU
   - Pressione `Cmd+Shift+V` (requer permissão de Acessibilidade)

2. **Gravar código:**
   - Clique no botão de microfone (verde = pronto, vermelho = gravando)
   - Fale seu código
   - Clique novamente para parar

3. **Resultado:**
   - O código será transcrito e formatado pelo Gemini
   - Será automaticamente colado no editor ativo (simula Cmd+V)

## Troubleshooting

### Atalho global não funciona
- Verifique se o app tem permissão de Acessibilidade
- Reinicie o app após conceder permissão

### Erro de API Key
- Verifique se a API Key está correta
- Certifique-se de que a API Key tem acesso ao modelo `gemini-1.5-flash`

### Áudio não grava
- Verifique permissão de Microfone nas Preferências do Sistema
- Teste o microfone em outro app

### Código não é colado
- Verifique permissão de Acessibilidade
- Tente colar manualmente (Cmd+V) para verificar se o texto está no clipboard

## Estrutura do Projeto

```
VibeFlow/
├── Sources/
│   ├── VibeFlowApp.swift      # App principal, Menu Bar, Janela flutuante
│   ├── ContentView.swift       # Interface principal
│   ├── VibeFlowViewModel.swift # Lógica de negócio
│   ├── AudioRecorder.swift    # Gravação de áudio (.m4a)
│   ├── GeminiService.swift    # Integração com Google Gemini
│   ├── ClipboardHelper.swift  # Clipboard e simulação de teclas
│   └── SettingsView.swift     # Tela de configurações
├── Package.swift              # Swift Package Manager
├── Info.plist                 # Permissões e configurações
└── README.md
```

## Dependências

- `GoogleGenerativeAI` (via Swift Package Manager)
  - URL: https://github.com/google/generative-ai-swift
  - Versão: 0.5.0+
