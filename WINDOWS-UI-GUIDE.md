# VoxAiGo — Guia Completo de UI/UX para Paridade Windows

> **Objetivo:** Este documento é a referência definitiva para replicar o app macOS no Windows (Tauri 2.0 + React).
> Contém TODOS os detalhes visuais, animações, posicionamento, cores, tipografia, e fluxos de estado.

---

## 1. DESIGN SYSTEM — "Matte Black & Gold"

Inspiração: estética de amplificadores Marshall. Fundo preto mate, acentos dourados, tipografia limpa.

### 1.1 Paleta de Cores (OBRIGATÓRIA)

```
BACKGROUNDS
─────────────────────────────────────────────
background       #0A0A0A    rgb(10, 10, 10)         Fundo principal de todas as janelas
surface          #141414    rgb(20, 20, 20)         Cards, sidebars, áreas elevadas
surfaceBorder    #1F1F1F    rgb(31, 31, 31)         Bordas sutis entre seções

ACCENT (GOLD — cor da marca)
─────────────────────────────────────────────
accent           #D4AF37    rgb(212, 175, 55)       Cor principal da marca (botões, ícones ativos, badges PRO)
accentLight      #E8D48B    rgb(232, 212, 139)      Versão clara para gradientes
accentMuted      #D4AF37 @ 15% opacity              Fundo sutil de badges e feature boxes

TEXT
─────────────────────────────────────────────
textPrimary      #F5F5F5    rgb(245, 245, 245)      Texto principal (quase branco)
textSecondary    #8A8A8A    rgb(138, 138, 138)      Labels, subtítulos
textDisabled     #555555    rgb(85, 85, 85)          Itens desativados

SEMANTIC
─────────────────────────────────────────────
danger           #FF4444    rgb(255, 68, 68)         Erros, alertas
success          #4ADE80    rgb(74, 222, 128)        Sucesso, permissões OK
speechActive     #F24040    rgb(242, 64, 64)         Indicador de fala ativa (vermelho)
transform        #A673FF    rgb(166, 115, 255)       Modo Transform (roxo)
```

### 1.2 Gradiente Gold (para logo, badges PRO, botões de upgrade)

```css
background: linear-gradient(135deg, #D4AF37, #E8D48B);
```

### 1.3 Cores por Idioma (nas notificações de troca de idioma)

```
PT  #008856   Verde escuro
EN  #2663EB   Azul
ES  #EB590D   Laranja
FR  #3B82F5   Azul claro
DE  #C98A05   Amarelo escuro
IT  #218C21   Verde
JA  #DB2626   Vermelho
KO  #0078BF   Azul marinho
ZH  #DB1440   Vermelho rosado
RU  #003D8C   Azul escuro
Outros  #6666A0   Roxo acinzentado
```

---

## 2. TIPOGRAFIA

Usar fonte do sistema (San Francisco no macOS / Segoe UI no Windows).

```
HIERARCHY
─────────────────────────────────────────────
Título principal     22px  bold
Título secundário    18px  semibold
Título de seção      15px  semibold
Label/corpo          13px  medium
Corpo menor          12px  regular
Caption/badge        11px  medium
Código/monospace     10px  bold, design: rounded    (badges de idioma, atalhos)
Ícone pequeno        9px   semibold                 (dentro de pills)
```

---

## 3. HUD DE GRAVAÇÃO — A Peça Central

### 3.1 Janela (Window)

```
Tipo:           Janela flutuante sem borda (borderless)
Tamanho:        500×100 px
Fundo:          TRANSPARENTE (a forma é desenhada no CSS/SwiftUI)
Sempre no topo: Sim (acima de TUDO, inclusive fullscreen)
Rouba foco:     NÃO (nonactivatingPanel — não tira foco do app do usuário)
Sombra:         Nenhuma
Clicável:       Sim (não é click-through)
Visível em:     Todos os espaços/desktops + fullscreen de outros apps
```

### 3.2 Posicionamento

```
┌──────────────────────────────────────────┐
│                                          │
│               (tela inteira)             │
│                                          │
│                                          │
│                                          │
│          ┌──────────────────┐            │
│          │   HUD capsule    │  ← 25% do fundo
│          └──────────────────┘            │
│                                          │
└──────────────────────────────────────────┘

x = (largura_tela / 2) - (largura_hud / 2)    // Centralizado horizontalmente
y = fundo_tela + (altura_tela × 0.25)          // 25% acima do fundo da tela
```

### 3.3 Formato: CÁPSULA (Capsule)

O HUD é uma cápsula (retângulo com bordas totalmente arredondadas). NÃO é um retângulo comum.

```
┌─────────────────────────────────────────────────┐
│  Bordas 100% arredondadas (border-radius: 9999px) │
└─────────────────────────────────────────────────┘
```

### 3.4 Estilos da Cápsula

```css
/* Base */
background: rgba(31, 31, 31, 0.85);      /* Color(white: 0.12, opacity: 0.85) */
border-radius: 9999px;                     /* Capsule() */

/* Borda padrão (quando NÃO é Pro/Trial) */
border: 1px solid;
border-image: linear-gradient(135deg, rgba(255,255,255,0.15), rgba(255,255,255,0.02)) 1;

/* Borda GOLD (quando AI está ativa — Pro ou Trial gravando) */
border: 1.5px solid;
border-image: linear-gradient(135deg, rgba(212,175,55,0.4), rgba(212,175,55,0.1)) 1;

/* Sombra GOLD (Pro/Trial gravando) */
box-shadow: 0 0 12px rgba(212,175,55,0.2);
```

### 3.5 Os 3 Estados do HUD

O HUD muda de tamanho e conteúdo conforme o estado:

```
ESTADO          LARGURA    ALTURA    CONTEÚDO
────────────────────────────────────────────────────────
idle            200px      56px      [Mic] "Segure" [⌥⌘]
                                     ou [✓ Colado] (após paste)
                                     ou [⚠ Erro] (após erro)

listening       440px      56px      [Mic+Wave] | "Ouvindo..." [PT] [Código]

processing      220px      56px      [✨ rotating] "Processando..."
```

**ANIMAÇÃO DE TRANSIÇÃO ENTRE TAMANHOS:**
```
spring(response: 0.45, dampingFraction: 0.75, blendDuration: 0.1)

Em CSS:
transition: width 0.45s cubic-bezier(0.34, 1.56, 0.64, 1);
```

### 3.6 Layout Detalhado — Estado IDLE (200×56px)

```
┌──────────────────────────────────────┐
│  padding: 18px horizontal, 14px vertical │
│                                      │
│  [Mic Icon]    "Segure"  ┌────────┐  │
│  (gold on     (13px,     │ ⌥  ⌘  │  │
│   white       secondary  └────────┘  │
│   circle)     color)     (shortcut   │
│   28×28                   badge)     │
└──────────────────────────────────────┘

Mic icon:
  - Círculo branco 28×28px
  - "mic.fill" icon 14px, cor gold (#D4AF37)
  - Se isVoxActive (Pro/Trial): círculo gold glow atrás (40×40, opacity 0.1, shadow gold 0.5)

Shortcut badge:
  - Fundo: rgba(255,255,255,0.1), border: rgba(255,255,255,0.08) 1px
  - border-radius: 6px
  - padding: 8px horizontal, 4px vertical
  - Font: 11px medium rounded
  - Windows: mostrar "Ctrl" "Space" em vez de "⌥" "⌘"
```

**Variação IDLE — Após paste bem-sucedido:**
```
┌──────────────────────────────────────┐
│  [✓ checkmark.circle.fill]  "Colado" │
│  (green)                     (green)  │
└──────────────────────────────────────┘
```

**Variação IDLE — Após erro:**
```
┌──────────────────────────────────────┐
│  [⚠ exclamation.triangle.fill] msg  │
│  (orange)                   (orange) │
└──────────────────────────────────────┘
```

### 3.7 Layout Detalhado — Estado LISTENING (440×56px)

```
┌────────────────────────────────────────────────────────────────┐
│  padding: 22px horizontal, 14px vertical                       │
│                                                                │
│  [Mic+Wave]  |  "Ouvindo..."  |  [OFFLINE] [PT] [Código]     │
│                                                                │
│  LEFT        DIV   CENTER      RIGHT                          │
└────────────────────────────────────────────────────────────────┘

LEFT SECTION (mic + ondas):
  - Mic icon com estados visuais (ver 3.8)
  - Barra de ondas sonoras (SoundWaveView) — 80×28px
  - Espaçamento entre mic e ondas: 10px

DIVIDER:
  - Linha vertical 1px × 28px, cor rgba(255,255,255,0.1)
  - padding horizontal: 8px de cada lado

CENTER:
  - Se isVoxActive: "Agente Vox Ouvindo..." (14px medium, cor gold)
  - Se não: "Ouvindo..." (14px medium, cor branca 0.9)

RIGHT SECTION (badges):
  - Se offline: badge "OFFLINE" (9px bold rounded, laranja, fundo orange 0.15)
  - Language pill: código do idioma em uppercase (ex: "PT")
  - Mode pill: ícone + nome do modo (ex: "⌨ Código")
  - Se Transform mode: pill com gradiente roxo→gold
  - Espaçamento entre pills: 8px
```

### 3.8 Mic Icon — Estados Visuais

```
ESTADO                    VISUAL
────────────────────────────────────────────────────────────
idle (quieto)             Círculo branco 28px + mic gold 14px
                          Se Pro: glow gold 40px atrás (opacity 0.4)

listening (sem fala)      Mesmo que idle mas com waveform ao lado
                          Glow gold pulsa suavemente (0.4→0.8, 1.2s loop)

listening (fala ativa)    Círculo VERMELHO 32px (pulsando 0.6→1.0, 0.4s loop)
audioLevel > 0.05         Mic BRANCO no vermelho
                          Se Pro: glow gold continua atrás

processing                Ícone muda para "sparkles" (✨) girando
                          Cor: gold (#D4AF37)
                          Se Transform: ícone "wand.and.stars", cor roxa

processing (girando)      Rotação contínua 360° em 2 segundos (linear, forever)
```

### 3.9 Ondas Sonoras (SoundWaveView)

```
Forma orgânica, NÃO barras discretas.
Duas camadas sobrepostas:

Camada traseira (blur):
  - Tamanho: 90×36px
  - Cor: branca (idle) ou vermelha (fala ativa), opacity 0.4
  - Gradiente: centro → borda (fade out)
  - blur: 2px
  - Frequência: 1.5

Camada frontal:
  - Tamanho: 80×28px
  - Cor: branca (idle) ou vermelha (fala ativa), sem blur
  - Gradiente: esquerda→direita (1.0 → 0.6 opacity)
  - Frequência: 2.0

Forma da onda:
  - path sinusoidal: sin(x × π × frequência + phase)
  - Amplitude: 2px (silêncio) → metade da altura (volume máximo)
  - Taper: sin(x × π) — diminui nas bordas (forma de sino)
  - Espelho vertical para criar forma de "bolha"
  - Phase random quando fala ativa (cria variação orgânica)

Animação:
  - Spring: response 0.15, damping 0.5 (super responsiva ao audioLevel)
  - Transição de cor: easeInOut 0.3s (branco↔vermelho)
```

### 3.10 Pills (Language + Mode)

**Language Pill:**
```css
/* Exemplo: "PT" */
font: 10px bold rounded;
color: #D4AF37;                              /* Sempre gold */
padding: 8px 5px;
background: rgba(212, 175, 55, 0.15);
border: 1px solid rgba(212, 175, 55, 0.3);
border-radius: 6px;
```

**Mode Pill:**
```css
/* Exemplo: "⌨ Código" */
font: 10px semibold;
color: white;
padding: 10px 5px;
background: #D4AF37;                        /* Gold sólido */
border-radius: 6px;
/* Ícone 9px + texto 10px, gap: 4px */
```

**Transform Pill (modo Transform ativo):**
```css
font: 10px semibold;
color: white;
padding: 10px 5px;
background: linear-gradient(90deg, #A673FF, #D4AF37);    /* Roxo → Gold */
border-radius: 6px;
/* Ícone: "wand.and.stars" */
```

**Offline Badge:**
```css
font: 9px bold rounded;
color: orange;
padding: 6px 4px;
background: rgba(255, 165, 0, 0.15);
border: 1px solid rgba(255, 165, 0, 0.3);
border-radius: 5px;
```

---

## 4. HUD DE NOTIFICAÇÕES (Language, Mode, Paste, etc.)

Aparecem temporariamente quando o usuário troca idioma, modo, ou cola última transcrição.

### 4.1 Janela (Window)

```
Tipo:           Janela flutuante sem borda (borderless)
Sempre no topo: Sim (screenSaver level)
Rouba foco:     NÃO (nonactivatingPanel)
Click-through:  SIM (ignoresMouseEvents = true) — não intercepta cliques
Auto-dismiss:   2 segundos + fade out (0.3s easeIn → opacity 0)
Sombra:         Nenhuma
```

### 4.2 Posicionamento

```
Centro da tela, ligeiramente acima do centro:

x = (largura_tela / 2) - (largura_notif / 2)
y = (altura_tela / 2) + 50    // Ligeiramente acima do centro
```

### 4.3 Animação de Entrada

```css
/* Aparecimento: spring pop-in */
/* De: scale 0.7, offset-y +15px, opacity 0 */
/* Para: scale 1.0, offset-y 0, opacity 1.0 */
transition: transform 0.45s cubic-bezier(0.34, 1.56, 0.64, 1),
            opacity 0.45s cubic-bezier(0.34, 1.56, 0.64, 1);

/* Desaparecimento: fade out */
transition: opacity 0.3s ease-in;
```

### 4.4 Container Base (HUDNotificationContainer)

```
Forma:     Cápsula (border-radius: 9999px)
Fundo:     surface (#141414) @ 85% opacity
Borda:     1px gradiente linear-gradient(135deg, rgba(255,255,255,0.15), rgba(255,255,255,0.02))
Padding:   24px horizontal, 16px vertical
```

### 4.5 Layout das Notificações

**Language Notification (260×64px):**
```
┌──────────────────────────────────────────────────┐
│                                                   │
│  ┌────┐  "Idioma" ✓          ┌──────┐            │
│  │ 🇧🇷 │  "Português"        │  PT  │            │
│  └────┘  (15px bold)          └──────┘            │
│  36×36                        (badge)             │
│                                                   │
└──────────────────────────────────────────────────┘

Ícone: círculo 36×36, fill cor_idioma @ 0.2, stroke cor_idioma @ 0.4, bandeira 18px no centro
Label "Idioma": 11px medium, white 0.5
Checkmark: 10px, cor do idioma
Nome: 15px bold, branco
Badge código: 11px bold rounded, cor do idioma, fundo cor @ 0.15, borda cor @ 0.3
```

**Mode Notification (240×64px):**
```
┌──────────────────────────────────────────────┐
│                                               │
│  ┌────┐  "Modo" ✓                            │
│  │ ⌨  │  "Código"                            │
│  └────┘  (15px bold)                          │
│  36×36                                        │
│                                               │
└──────────────────────────────────────────────┘

Ícone: círculo 36×36, fill mode.color @ 0.2, stroke mode.color @ 0.4, ícone do modo 16px
Label "Modo": 11px medium, white 0.5
```

**Paste Last Notification (280×64px):**
```
┌───────────────────────────────────────────────────┐
│                                                    │
│  ┌────┐  "Colado" ✓                               │
│  │ 📋 │  "Hello world, this is a test tr..."      │
│  └────┘  (12px medium, truncado 30 chars)          │
│  36×36                                             │
│                                                    │
└───────────────────────────────────────────────────┘
```

**No History Notification (260×64px):**
```
┌──────────────────────────────────────────────────┐
│                                                   │
│  ┌────┐  "Histórico vazio"                       │
│  │ 📥 │  "Nenhuma transcrição salva"             │
│  └────┘  (11px, white 0.5)                        │
│  36×36                                            │
│                                                   │
└──────────────────────────────────────────────────┘
```

---

## 5. JANELA PRINCIPAL (MainWindow)

### 5.1 Janela (Window)

```
Tamanho:        800×600 px (default)
Tamanho mínimo: 720×520 px
Tipo:           Janela normal (titled, closable, resizable, miniaturizable)
Tema:           Dark mode forçado
```

### 5.2 Layout: Sidebar + Detail

```
┌──────────────────────┬─────────────────────────────────────────┐
│                      │                                         │
│    SIDEBAR           │          DETAIL AREA                    │
│    (200-220px)       │          (resto da largura)             │
│                      │                                         │
│  ┌────────────┐      │                                         │
│  │ 🎵 VoxAiGo│      │  [Conteúdo muda conforme seleção]      │
│  └────────────┘      │                                         │
│                      │                                         │
│  🏠 Home            │                                         │
│  🌐 Idiomas         │                                         │
│  🎯 Modos           │                                         │
│  ✂️ Snippets        │                                         │
│  ✍️ Estilo          │                                         │
│  ⚙️ Ajustes         │                                         │
│                      │                                         │
│  ─────────────       │                                         │
│  v3.0.0              │                                         │
│  42 transcrições     │                                         │
│  1h 23m gravados     │                                         │
└──────────────────────┴─────────────────────────────────────────┘
```

### 5.3 Sidebar Styling

```css
/* Container */
background: #141414;                /* surface */
min-width: 200px;
max-width: 220px;

/* Logo header */
/* Ícone custom 28×28: quadrado preto arredondado com 5 barras gold */
/* Texto "VoxAiGo" 15px semibold */
padding: 16px horizontal;

/* Navigation items */
padding: 12px horizontal, 8px vertical;
border-radius: 6px;
font: 13px medium;
icon: 14px;
gap (icon ↔ text): 10px;

/* Item normal */
color: #8A8A8A;                     /* textSecondary */

/* Item selecionado */
background: rgba(212, 175, 55, 0.12);
color: white;
icon-color: #D4AF37;               /* gold */

/* Item hover */
background: rgba(255, 255, 255, 0.05);

/* Footer stats */
font: 11px;
color: #8A8A8A;
```

### 5.4 Logo VoxAiGo (Brand Mark)

```
Composição: Quadrado preto arredondado com 5 barras verticais gold dentro

Tamanhos: 28×28 (sidebar), 48×48 (wizard), 64×64 (trial), 72×72 (modal grande)

Quadrado:
  - Fundo: preto puro #000000
  - Border-radius: 20% do tamanho
  - Borda: gold @ 0.3 opacity, 1-2px

Barras internas (5 barras):
  - Alturas relativas: [22%, 42%, 58%, 48%, 30%] do tamanho total
  - Largura: 10% do tamanho
  - Espaçamento: 6% do tamanho entre barras
  - Border-radius: 4% do tamanho
  - Cor: gradiente gold (#D4AF37 → #E8D48B)
  - Sombra: gold @ 0.3, blur 3% do tamanho
  - Centralizadas horizontal e verticalmente
```

---

## 6. JANELA DE LOGIN

### 6.1 Janela (Window)

```
Tamanho:   480×580 px
Tipo:      Titled, miniaturizable (SEM botão de fechar — login é obrigatório)
Título:    "Bem-vindo ao VoxAiGo"
```

### 6.2 Layout

```
┌──────────────────────────────────────────────┐
│          padding: 32px                        │
│                                               │
│    ┌────┐                                     │
│    │Logo│  "VoxAiGo"                         │
│    └────┘  (22px bold)                        │
│    40×40                                      │
│                                               │
│  ┌──────────────────────────────────────┐     │
│  │  Card (surface + 1px surfaceBorder)  │     │
│  │  border-radius: 16px                 │     │
│  │  padding: 32px                       │     │
│  │                                      │     │
│  │  "Welcome back" (18px semibold)      │     │
│  │                                      │     │
│  │  ┌──────────────────────────────┐    │     │
│  │  │  G  Continuar com Google     │    │     │
│  │  └──────────────────────────────┘    │     │
│  │  44px height, border: surfaceBorder  │     │
│  │  border-radius: 10px                 │     │
│  │                                      │     │
│  │  ─── ou ───                          │     │
│  │  (divider com "ou" no centro)        │     │
│  │                                      │     │
│  │  [Senha] [Magic Link]  ← tabs        │     │
│  │  ────────────────────                │     │
│  │  Email: [________________]           │     │
│  │  Senha: [________________]           │     │
│  │                                      │     │
│  │  ┌──────────────────────────────┐    │     │
│  │  │      Entrar                  │    │     │
│  │  └──────────────────────────────┘    │     │
│  │  Gold gradient, 44px, radius 10px    │     │
│  │                                      │     │
│  │  "Não tem conta? Criar conta"        │     │
│  │  (13px, gold link)                   │     │
│  └──────────────────────────────────────┘     │
│                                               │
│  "Continuar sem I.A." (13px, textSecondary)   │
└──────────────────────────────────────────────┘

Tabs (Senha / Magic Link):
  - 13px medium
  - Ativa: gold text, fundo gold @ 0.2, border-radius 8px
  - Inativa: textSecondary, transparente

Campos de texto:
  - 13px, padding 12px
  - Fundo: background (#0A0A0A)
  - Borda: 1px surfaceBorder (#1F1F1F)
  - Border-radius: 8px
  - Foco: borda gold

Status messages:
  - Fundo: cor @ 0.1 opacity
  - Border-radius: 8px
  - Padding: 12px
  - Texto: 12px
  - Erro: danger (#FF4444)
  - Sucesso: success (#4ADE80)
```

### 6.3 3 Modos da Tela de Login

```
1. Sign In    → Email + Senha + "Esqueceu a senha?"
2. Sign Up    → Email + Senha + "Já tem conta?"
3. Reset      → Apenas email + "Voltar para login"

Transição: animação de slide (0.2s easeInOut)
```

---

## 7. MODAIS DE TRIAL E UPGRADE

### 7.1 Welcome Trial Modal (400×560px)

```
┌──────────────────────────────────────────────┐
│             padding: 28-32px                  │
│                                               │
│         [Logo 72×72]                          │
│    "Seu Trial Pro está Ativo!"               │
│    (22px bold)                                │
│    "7 dias grátis de todos os recursos"       │
│    (14px, textSecondary)                      │
│                                               │
│  ┌──────────────────────────────────────┐     │
│  │  Feature box (accentMuted bg)        │     │
│  │  border-radius: 12px, padding: 16px  │     │
│  │                                      │     │
│  │  ✨ Agente Vox I.A.                  │     │
│  │  🎙 Todos os 15 modos de I.A.       │     │
│  │  🌐 30 idiomas                       │     │
│  │  📝 Formatação inteligente           │     │
│  │                                      │     │
│  │  Cada item: ícone 13px em círculo    │     │
│  │  gold @ 0.2 + texto 13px             │     │
│  └──────────────────────────────────────┘     │
│                                               │
│  "7 dias — sem cartão necessário"            │
│  "Até 50 transcrições com I.A."              │
│  (12px, textSecondary)                        │
│                                               │
│  ┌──────────────────────────────────────┐     │
│  │      Começar Trial Pro               │     │
│  │  (gold gradient, 44px, full width)   │     │
│  └──────────────────────────────────────┘     │
│                                               │
│  "Continuar sem I.A." (13px, textSecondary)   │
└──────────────────────────────────────────────┘
```

### 7.2 Trial Expired Modal (420×620px)

```
Mesma estrutura, mas com:
- Ícone de relógio vermelho sobre o logo
- "Seu Trial Pro Expirou"
- Box "O que muda" com itens em laranja (downgrade)
- Box "O que continua" com itens em verde (mantém)
- Toggle Mensal/Anual com preços
- Botão "Assinar Pro" gold

Toggle preço:
  ┌────────┬────────┐
  │ Anual  │ Mensal │
  └────────┴────────┘
  Selecionado: fundo branco, texto gold
  Não selecionado: transparente, textSecondary
  Badge "-25%": gold text, gold @ 0.2 fundo

Preço display: "R$" 15px + "29,90" 36px bold + "/mês" 14px
```

### 7.3 Monthly Limit Modal (420×560px)

```
- Logo com badge de cadeado vermelho (offsetX: 28)
- "Limite Mensal Atingido"
- "Você usou todas as 75 transcrições..."
- Opções em caixa com fundo vermelho @ 0.06
- Botão upgrade
```

### 7.4 Upgrade Modal (420×520px)

```
- NSPanel level: screenSaver (acima de tudo)
- Contextual: mostra o modo/idioma que o usuário tentou usar
- Toggle Anual/Mensal
- Lista de benefícios Pro
- Botão "Assinar Pro" gold gradient
- "Continuar sem I.A." link
```

---

## 8. SETUP WIZARD (Onboarding)

### 8.1 Janela (Window)

```
Tamanho:   680×580 px
Tipo:      Titled, closable
Título:    "Configurar VoxAiGo"
```

### 8.2 Layout: Two Panels

```
┌──────────────────────────┬───────────────────────────────────┐
│                          │                                   │
│    LEFT PANEL (40%)      │     RIGHT PANEL (60%)             │
│    Fundo: #000000        │     Fundo: #0A0A0A               │
│                          │                                   │
│    [Logo animado]        │     [Título do step]              │
│    ou                    │     [Subtítulo]                   │
│    [Progress visual]     │                                   │
│                          │     [Conteúdo do step]            │
│    Step title            │     (scroll se necessário)        │
│    Step subtitle         │                                   │
│                          │     ┌────────────────────────┐    │
│                          │     │ Progress bar (gold)    │    │
│                          │     │ [Voltar] [Step X/7]    │    │
│                          │     │        [Continuar]     │    │
│                          │     └────────────────────────┘    │
│                          │                                   │
└──────────────────────────┴───────────────────────────────────┘
```

### 8.3 Steps do Wizard (7 passos)

```
Step 0: LOGIN
  - Se já logado: checkmark verde + email
  - Se não: LoginView embutido (completo)

Step 1: PERMISSÕES
  - 3 PermissionCards: Microfone, Acessibilidade, Input Monitoring
  - Timer de 1s checa permissões continuamente
  - Cada card: ícone 44×44 em círculo + título + descrição + botão/checkmark
  - Concedida: fundo gold @ 0.05, checkmark gold 24px
  - Pendente: fundo surface, botão borderedProminent

Step 2: PRIMEIRA GRAVAÇÃO (OBRIGATÓRIO)
  - Instrução para segurar Ctrl+Space e falar
  - Observa NotificationCenter .transcriptionComplete
  - Mostra resultado real da transcrição
  - NÃO pode avançar sem gravar pelo menos 1x

Step 3: TREINAR MODOS
  - Instrução: pressione Alt+M 3 vezes
  - Observa .modeChanged — conta mudanças
  - Progress: X/3 ciclos
  - Mostra modo atual com ícone e cor

Step 4: WAKE WORD TEST (pode pular)
  - Instrução: diga "Hey Vox, código"
  - Observa .wakeWordCommand
  - Mostra comando detectado
  - Botão "Pular" disponível

Step 5: TROCAR IDIOMA (pode pular)
  - Picker de idiomas
  - Observa .languageChanged
  - Botão "Pular" disponível

Step 6: PRONTO (Cheat Sheet)
  - Lista de atalhos com badges:
    - Ctrl+Space → Gravar
    - Alt+M → Trocar Modo
    - Alt+L → Trocar Idioma
    - Ctrl+, → Configurações
    - Ctrl+Shift+V → Mostrar/Esconder
  - Botão "Começar a usar o VoxAiGo" (gold gradient)
```

### 8.4 Progress Bar

```css
/* Barra no rodapé do right panel */
height: 3px;
background: rgba(212, 175, 55, 0.2);     /* track */
foreground: linear-gradient(90deg, #D4AF37, #E8D48B);  /* fill */
width: (currentStep + 1) / totalSteps * 100%;
border-radius: 2px;
transition: width 0.3s ease;
```

---

## 9. CONVERSATION REPLY HUD

### 9.1 Janela (Window)

```
Tipo:           NSPanel borderless, nonactivatingPanel
Tamanho:        440×(64-200)px — muda com animação
Sempre no topo: screenSaver level
Click-through:  NÃO (precisa de interação)
Dismiss:        Timeout 25s OU botão close
```

### 9.2 4 Estados

```
ESTADO          TAMANHO     CONTEÚDO
─────────────────────────────────────────────
translating     440×64      Spinner + "Lendo mensagem..."
ready           440×200     Tradução + badges de/para + prompt para gravar
recording       440×80      Mic pulsando + ondas + "Gravando resposta..."
processing      440×64      Sparkles girando + "Traduzindo sua resposta..."
```

### 9.3 Estilo

```css
/* Container */
background: rgba(20, 20, 20, 0.95);      /* quase opaco */
border-radius: 30px;                       /* super arredondado */
padding: 20-24px horizontal, 12-20px vertical;

/* Borda dinâmica */
border: 1.5px solid;
/* Normal: linear-gradient(135deg, rgba(255,255,255,0.15), rgba(255,255,255,0.02)) */
/* Recording: linear-gradient(135deg, rgba(242,64,64,0.5), rgba(242,64,64,0.1)) */

/* Animação de resize */
transition: height 0.22s ease-in-out;
```

### 9.4 Language Badges (de → para)

```css
/* Exemplo: "PT  Português" */
font: 10px bold;
padding: 10px 5px;
background: rgba(cor_idioma, 0.12);
border: 1px solid rgba(cor_idioma, 0.28);
border-radius: 6px;
```

### 9.5 Countdown Bar

```css
/* Barra de timeout no fundo do HUD */
height: 3px;
background: rgba(255, 255, 255, 0.05);    /* track */
foreground: linear-gradient(90deg, #D4AF37, #E8D48B);  /* fill */
width: timeoutProgress * 100%;             /* diminui de 100% → 0% em 25s */
transition: width 0.08s linear;
```

---

## 10. SYSTEM TRAY (Menu Bar / Tray Icon)

### 10.1 Ícone

```
SF Symbol: "waveform" (16pt, medium weight)
No Windows: usar ícone SVG equivalente de waveform no system tray
```

### 10.2 Estrutura do Menu (Right-Click)

```
VoxAiGo 3.0.0                              (disabled, header)
────────────────────────────────────────
[✈️ Modo Offline — transcrição simplificada]  (só se offline ativo)
user@email.com — Grátis: 23/75             (disabled, status)
────────────────────────────────────────
Mostrar/Esconder
────────────────────────────────────────
Modos              →  [Submenu: 15 modos]
                       Modos bloqueados: texto dimmed + ◆ prefix
                       Modo ativo: checkmark
                       ───
                       Próximo (Alt+M)
────────────────────────────────────────
Idioma: 🇧🇷 Português                     (disabled, mostra atual)
Idiomas Favoritos   →  [Submenu: favoritos]
                       Idiomas bloqueados: 🔒 prefix + texto dimmed
                       ───
                       Próximo (Alt+L)
────────────────────────────────────────
Microfone           →  [Submenu: dispositivos]
                       Dispositivo ativo: checkmark
                       Padrão: "(Padrão)" suffix
────────────────────────────────────────
Abrir VoxAiGo                              (abre MainWindow)
[Modo Offline toggle]                      (só Pro/Dev/já-ativo)
────────────────────────────────────────
Histórico                                  (Alt+Y)
Snippets
Estatísticas
Colar Última Transcrição (Alt+P)
────────────────────────────────────────
Configurações                              (Alt+,)
Suporte
────────────────────────────────────────
Sair                                       (Alt+Q)
```

### 10.3 Plan Status Indicator (na linha do email)

```
Pro:           só email, sem indicador
Trial:         "email — Pro Trial: 5d (23/50)"
Grátis:        "email — Grátis: 23/75"
Grátis limite: "email — Grátis: limite atingido"
Não logado:    Menu mínimo (só "Fazer Login..." e "Sair")
```

---

## 11. CONFIGURAÇÕES (Settings)

### 11.1 Janela: Embedded no MainWindow (sidebar → Ajustes)

### 11.2 Tabs: 4 tabs horizontais

```
┌──────────────────────────────────────────────┐
│  [Geral]  [Idioma]  [Atalhos]  [Permissões] │
│  ─────────────────────────────────────────── │
│                                               │
│  [Conteúdo do tab selecionado]               │
│                                               │
└──────────────────────────────────────────────┘

Tab styling:
  - Altura: 50px
  - Ícone: 16px
  - Label: 11px
  - Normal: textSecondary, transparente
  - Selecionado: white text, gold @ 0.12 fundo, border-radius: 8px
```

### 11.3 SettingsCard (container reutilizável)

```css
background: rgba(20, 20, 20, 0.5);        /* surface @ 50% */
border: 1px solid #1F1F1F;
border-radius: 12px;
padding: 16px;

/* Header */
icon: 12px, gold;
title: 13px semibold;
gap: 8px;

/* Toggle rows */
padding: 8px vertical;
divider between rows: 1px, padding-left: 32px;
```

---

## 12. ANIMAÇÕES MASTER REFERENCE

```
USO                              TIPO         VALORES
─────────────────────────────────────────────────────────────────
HUD resize (idle↔listening)      Spring       response: 0.45, damping: 0.75
Notificação pop-in               Spring       response: 0.45, damping: 0.65
Toast slide-in                   Spring       response: 0.3, damping: 0.7
Mic pulse (fala ativa)           Ease         0.4s, repeatForever, autoreverses
Sparkles rotation                Linear       2.0s, repeatForever, no autoreverse
Tab switching                    EaseInOut    0.15s
Conversation reply resize        EaseInOut    0.22s
Notification fade-out            EaseIn       0.3s
Sound wave response              Spring       response: 0.15, damping: 0.5
Gold glow pulse                  EaseInOut    1.2s, repeatForever, autoreverses
Progress bar update              Linear       0.08s
Wizard step transition           EaseInOut    0.3s (default)
```

---

## 13. FLUXO DE ESTADOS COMPLETO

### 13.1 Fluxo de Gravação

```
[App idle — HUD escondido]
         │
         ▼  Usuário segura Ctrl+Space
[HUD aparece: estado IDLE]
         │
         ▼  Gravação inicia (after debounce)
[HUD expande: estado LISTENING 440px]
  - Ondas sonoras respondem ao áudio
  - Mic: branco (silêncio) → vermelho pulsante (fala)
  - Se Pro: borda gold + glow gold
  - Mostra: idioma + modo pills
         │
         ▼  Usuário solta Ctrl+Space
[Verifica se houve fala]
    │                    │
    ▼ Sem fala           ▼ Com fala
[HUD: erro "Sem fala"]  [HUD contrai: estado PROCESSING 220px]
[Fecha em 3s]            - Sparkles girando (gold ou roxo)
                         - "Processando..." ou "Transformando..."
                                │
                     ┌──────────┴──────────┐
                     │                     │
                     ▼ Sucesso             ▼ Erro
              [Texto copiado]       [HUD: erro laranja]
              [Auto-paste Ctrl+V]   [Fecha em 3s]
              [HUD: ✓ "Colado"]
              [Fecha em 2s]
```

### 13.2 Feature Gating

```
Usuário tenta gravar
         │
         ▼
[Verifica modo]
  │ Free mode (text) → OK, continua
  │ Pro mode → Verifica plano
         │
    ┌────┴────┐
    │         │
    ▼ Pro     ▼ Free/Trial expired
  [OK]      [Mostra Upgrade Modal]
              [Bloqueia gravação]

    ▼ Trial ativo
  [OK, mas verifica limite]
    │
    ├─ < 50 transcriptions → OK
    │
    └─ ≥ 50 transcriptions → [Trial Limit Modal]
                              [Switch to free mode]

Verificação de idioma: mesma lógica
  - Free: só PT + EN
  - Pro/Trial: todos os 30 idiomas
```

### 13.3 Fluxo de Autenticação

```
[App inicia]
    │
    ├─ Não logado → [Login Window (SEM botão fechar)]
    │                   │
    │                   ├─ Google OAuth → callback → sucesso
    │                   ├─ Email + Senha → submit → sucesso
    │                   └─ Magic Link → email enviado → link clicado → sucesso
    │                        │
    │                        ▼
    │               [Login window fecha]
    │               [Se !onboardingCompleted → Wizard]
    │               [Se onboardingCompleted → App normal]
    │
    └─ Já logado → [Verifica onboarding]
                      │
                      ├─ Completo → App normal
                      └─ Não completo → Wizard
```

---

## 14. RESPONSIVE & DARK MODE

### 14.1 Sempre Dark Mode

```javascript
// Forçar dark mode em TODA a aplicação
// Não existe modo claro. Todas as cores são para dark mode.
document.documentElement.setAttribute('data-theme', 'dark');
```

### 14.2 Tamanhos de Janela

```
HUD Recording:      500×100   (borderless, floating)
HUD Notifications:  240-280×64 (borderless, floating, click-through)
Conversation Reply: 440×(64-200) (borderless, floating)
Login:              480×580   (titled, no close button)
Main Window:        800×600   (titled, resizable, min: 720×520)
Wizard:             680×580   (titled, closable)
Upgrade Modal:      420×520   (titled, closable, floating)
Welcome Trial:      400×560   (titled, closable)
Trial Expired:      420×620   (titled, closable)
Monthly Limit:      420×560   (titled, closable)
Settings:           Embedded in MainWindow
History:            550×600   (titled, closable, resizable, min: 400×400)
```

---

## 15. ATALHOS WINDOWS

```
AÇÃO                     ATALHO WINDOWS        macOS EQUIVALENTE
──────────────────────────────────────────────────────────────
Hold-to-talk             Ctrl+Space            ⌥⌘
Trocar modo              Alt+M                 ⌃⇧M
Trocar idioma            Alt+L                 ⌃⇧L
Colar última             Alt+P                 ⌃⇧V
Conversation reply       Alt+R                 ⌃⇧R
Abrir configurações      Ctrl+,                ⌘,
Abrir histórico          Ctrl+Y                ⌘Y
Mostrar/esconder         Ctrl+Shift+V          ⌘⇧V
```

---

## 16. DEBOUNCE & TIMING

```
Cycle language debounce:    300ms
Cycle mode debounce:        300ms
Paste last debounce:        500ms
Conversation reply debounce: 500ms
Auto-dismiss notification:  2000ms (2s)
Error display duration:     3000ms (3s)
Success display duration:   2000ms (2s)
HUD fade-out:              300ms
Subscription sync interval: 300s (5 min)
Permission check interval:  1000ms (1s, durante wizard)
Conversation reply timeout: 25s
```

---

## 17. CHECKLIST DE PARIDADE VISUAL

Use esta checklist para verificar se o Windows está 100% visual:

- [ ] HUD em formato cápsula (border-radius: 9999px), NÃO retângulo
- [ ] HUD posicionado a 25% do fundo da tela, centralizado
- [ ] HUD NÃO rouba foco do app anterior
- [ ] HUD expande/contrai com animação spring (não linear)
- [ ] Ondas sonoras orgânicas (não barras discretas)
- [ ] Mic muda: branco→vermelho (fala) com pulso
- [ ] Sparkles girando durante processing
- [ ] Golden glow quando Pro está gravando (borda + sombra gold)
- [ ] Pills de idioma e modo no HUD
- [ ] Notificações pop-in com spring (scale 0.7→1.0 + offset)
- [ ] Notificações auto-dismiss 2s com fade-out
- [ ] Notificações são click-through (não interceptam mouse)
- [ ] Login SEM botão de fechar (obrigatório)
- [ ] Sidebar com background #141414
- [ ] Item selecionado na sidebar: fundo gold @ 0.12
- [ ] Todas as cores seguem VoxTheme exatamente
- [ ] Dark mode forçado (sem light mode)
- [ ] Upgrade modal aparece acima de tudo (screenSaver level)
- [ ] Wizard tem 2 painéis (40% dark + 60% content)
- [ ] Step 2 do wizard obrigatório (real transcription)
- [ ] Conversation Reply tem 4 estados com resize animado
- [ ] Countdown bar gold no Conversation Reply
- [ ] System tray mostra plan status dinâmico
- [ ] Modos bloqueados no menu: texto dimmed + ◆ prefix
