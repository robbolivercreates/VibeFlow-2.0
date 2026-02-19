# VibeFlow - Product Plan & Business Strategy

> Documento consolidado de todas as decisões tomadas em 2026-02-17.
> Este documento serve como fonte de verdade para o desenvolvimento do produto.

---

## 1. Visão Geral do Produto

**VibeFlow** é um aplicativo desktop (menu bar/system tray) que converte voz em texto formatado usando IA (Google Gemini). Focado em produtividade para desenvolvedores e profissionais.

- **Versão atual:** 2.3.0 (macOS)
- **Modelo de IA:** Gemini 2.5 Flash (com thinkingBudget: 0)
- **Plataformas alvo:** macOS + Windows
- **Público alvo:** Mercado brasileiro (profissionais, devs, escritores)

---

## 2. Mudança de Modelo de Negócio

### De: BYOK (Bring Your Own Key)
- Usuário insere sua própria API key do Google
- Barreira alta para público não-técnico brasileiro
- Custo zero para o operador

### Para: Subscription (SaaS)
- Usuário faz login, paga mensalidade e usa
- API key fica no servidor (usuário nunca vê)
- UX muito mais simples: baixou → cadastrou → usa

---

## 3. Pricing Definido

| Plano | Preço | Transcrições | Features |
|-------|-------|-------------|----------|
| **Free** | R$0 | 100/mês | Text + Code, PT+EN, básico |
| **Pro Mensal** | R$19,90/mês | Ilimitado | Tudo desbloqueado |
| **Pro Anual** | R$14,90/mês (R$178,80/ano) | Ilimitado | Tudo desbloqueado |

### Comparação com concorrente
- **Glaido:** $20/mês USD (~R$120), macOS only, 2.000 palavras/semana no free
- **VibeFlow:** R$19,90/mês (~6x mais barato), Mac + Windows, 100 transcrições/mês no free

---

## 4. Feature Gating (Free vs Pro)

| Funcionalidade | Free | Pro |
|----------------|------|-----|
| Transcrições/mês | 100 | Ilimitado |
| Modos de transcrição | Text + Code (2) | Todos os 5 (Text, Code, Email, UX, Command) |
| Idiomas de output | PT + EN (2) | Todos os 15+ |
| Auto-paste | Sim | Sim |
| Clarify text | Não | Sim |
| Style learning (IA personalizada) | Não | Sim |
| Snippets | Não | Sim |
| Histórico | Últimas 10 | Últimas 50 |
| Analytics/Gamificação | Básico (contador) | Completo (níveis, achievements, streaks) |
| Atalhos customizáveis | Não (padrão fixo) | Sim |
| Suporte | Comunidade | Prioritário |

### Lógica do gating
- **Free dá o essencial** → Text + Code em PT/EN, 100 usos = suficiente para viciar
- **Pro desbloqueia o "uau"** → Command Mode, Email Mode, Style Learning, todos os idiomas
- Quando usuário tenta recurso Pro → modal de upsell com botão "Assinar Pro"

---

## 5. Custo da API por Usuário

### Modelo: Gemini 2.5 Flash (com thinkingBudget: 0)

**Preço por token:**
- Audio input: $1.00 / 1M tokens
- Text input: $0.30 / 1M tokens
- Output: $0.80 / 1M tokens
- Tokenização de áudio: 25 tokens/segundo

**Custo por transcrição (~15s de áudio):**
- Áudio (375 tokens): $0.000375
- Prompt (800 tokens): $0.000240
- Output (200 tokens): $0.000160
- **Total: ~$0.000775 (~R$0.0047)**

**Custo mensal por perfil de usuário:**

| Perfil | Transcrições/mês | Custo/mês | Margem (R$19,90) |
|--------|-----------------|-----------|-------------------|
| Free (100/mês) | 100 | R$0,47 | N/A (não paga) |
| Pro leve (200/mês) | 200 | R$0,94 | 95% |
| Pro médio (500/mês) | 500 | R$2,35 | 88% |
| Pro intenso (1000/mês) | 1000 | R$4,69 | 76% |

### Nota sobre o modelo Gemini
- Gemini 2.0 Flash foi **descontinuado em 3 de março de 2026**
- Migrado para Gemini 2.5 Flash na versão 2.3.0
- **thinkingBudget: 0** desabilita o "thinking mode" → velocidade igual ao 2.0, inteligência do 2.5
- SDK GoogleGenerativeAI (Swift) foi **removido** — app usa REST direto via URLSession

---

## 6. Arquitetura Técnica

### Arquitetura atual (v2.3.0 - BYOK)
```
App macOS (Swift) → REST direto → Gemini API (key do usuário)
```

### Arquitetura alvo (Subscription)
```
┌─────────────────────────────────────────────┐
│                SUPABASE (grátis)             │
│                                             │
│  ┌─────────┐  ┌──────────┐  ┌───────────┐  │
│  │  Auth   │  │ Database │  │   Edge    │  │
│  │         │  │          │  │ Functions │  │
│  │ Login   │  │ users    │  │           │  │
│  │ Signup  │  │ subs     │  │ /transcr  │  │
│  │ JWT     │  │ usage    │  │ /validate │  │
│  └─────────┘  └──────────┘  └─────┬─────┘  │
│                                   │         │
└───────────────────────────────────┼─────────┘
                                    │
                              SUA API KEY
                                    │
                                    ▼
                            ┌──────────────┐
                            │  Google      │
                            │  Gemini API  │
                            └──────────────┘

┌──────────────┐        Webhooks
│    Eduzz     │ ──────────────────► Supabase DB
│   (PIX +     │   "assinatura      (atualiza status
│    Cartão)   │    ativa/cancelada") do usuário)
└──────────────┘
```

### Stack técnica

| Componente | Tecnologia |
|------------|------------|
| App macOS | Swift 5.9 + SwiftUI + AppKit |
| App Windows | Tauri 2.0 (Rust + React/TypeScript) |
| Backend | Supabase (Auth + PostgreSQL + Edge Functions) |
| Pagamento | Eduzz (PIX, boleto, cartão, recorrência) |
| IA | Google Gemini 2.5 Flash (REST API) |
| Landing page | Next.js (já existe em vibeflow-lp/) |

---

## 7. Plataforma Windows

### Por que Windows é prioridade
- Maioria do público brasileiro usa Windows
- Glaido (concorrente) é macOS only → oportunidade de mercado
- Mesmo backend serve Mac e Windows

### Tecnologia: Tauri 2.0
- App size: ~10 MB (vs ~150 MB Electron)
- RAM: ~30-40 MB (vs ~200-300 MB Electron)
- Backend em Rust (seguro, performático)
- Frontend em React + Tailwind
- WebView2 no Windows (Edge/Chromium)

### Equivalência de funcionalidades Mac → Windows

| Mac (Swift/AppKit) | Windows (Tauri/Rust) |
|--------------------|----------------------|
| Menu bar (NSStatusItem) | System Tray (Tauri built-in) |
| Global hotkeys (Carbon) | tauri-plugin-global-shortcut |
| Áudio (AVFoundation) | cpal crate (Rust) |
| Clipboard (NSPasteboard) | Tauri clipboard API |
| Auto-paste (CGEvent Cmd+V) | Windows SendInput Ctrl+V |
| Launch at login (SMAppService) | Windows Registry |
| Sons (NSSound) | rodio crate (Rust) |
| UserDefaults | tauri-plugin-store (JSON) |
| SwiftUI views | React + Tailwind |

### O que é 100% reutilizável (não precisa reescrever)
- Chamadas REST ao Gemini (HTTP puro)
- System prompts (todos os 5 modos)
- Lógica de modos, temperaturas, tokens
- cleanMarkdown() (lógica de texto)
- Toda a UI/UX (design, fluxos — conceito se mantém)

---

## 8. Roadmap de Implementação

### Fase 1 — Backend (Supabase)
- [ ] Auth (cadastro/login por email)
- [ ] Banco de dados (tabelas: users, subscriptions, usage_log)
- [ ] Edge Function: proxy de transcrição (recebe áudio → valida auth + sub → chama Gemini → devolve texto)
- [ ] Edge Function: webhook da Eduzz (ativa/desativa assinatura)
- [ ] Controle de free tier (conta transcrições por mês)
- [ ] Rate limiting (proteção contra abuso)

### Fase 2 — Atualizar App Mac (v3.0)
- [ ] Trocar chamada direta ao Gemini → chamar backend Supabase
- [ ] Adicionar tela de login/cadastro
- [ ] Adicionar tela "Assinar Pro" (abre checkout Eduzz)
- [ ] Implementar feature gating (Free vs Pro)
- [ ] Mostrar contador de uso para plano Free
- [ ] Modal de upsell quando tenta recurso Pro
- [ ] Remover campo de API key do Settings

### Fase 3 — App Windows (Tauri 2.0)
- [ ] Estrutura Tauri + system tray + atalhos globais
- [ ] Captura de áudio (cpal) + envio ao backend
- [ ] UI em React (replicar fluxos do Mac)
- [ ] Auto-paste via SendInput, clipboard, sons
- [ ] Settings, histórico, analytics, gamificação
- [ ] Gerar installer .exe

### Fase 4 — Landing Page + Distribuição
- [ ] Atualizar LP com download Mac + Windows
- [ ] Integrar checkout Eduzz na LP
- [ ] SEO para "ditado por voz", "voice to text Windows Brasil"
- [ ] Página de pricing com Free vs Pro

---

## 9. Tabelas do Banco de Dados (Supabase)

### users (extends Supabase auth.users)
```sql
- id (UUID, FK → auth.users)
- email (text)
- name (text)
- plan (enum: 'free', 'pro')
- subscription_status (enum: 'active', 'cancelled', 'expired')
- eduzz_subscription_id (text, nullable)
- free_transcriptions_used (int, default 0)
- free_transcriptions_reset_at (timestamp)
- created_at (timestamp)
- updated_at (timestamp)
```

### usage_log
```sql
- id (UUID)
- user_id (UUID, FK → users)
- mode (text: 'code', 'text', 'email', 'ux_design', 'command')
- audio_duration_seconds (float)
- output_length (int)
- language (text)
- created_at (timestamp)
```

### subscriptions
```sql
- id (UUID)
- user_id (UUID, FK → users)
- plan (enum: 'pro_monthly', 'pro_annual')
- status (enum: 'active', 'cancelled', 'expired', 'past_due')
- eduzz_transaction_id (text)
- started_at (timestamp)
- expires_at (timestamp)
- cancelled_at (timestamp, nullable)
```

---

## 10. Edge Function: Proxy de Transcrição (pseudocódigo)

```typescript
// POST /transcribe
async function handler(req) {
  // 1. Verificar autenticação
  const user = await verifyJWT(req.headers.authorization)
  if (!user) return 401

  // 2. Verificar assinatura ou free tier
  if (user.plan === 'free') {
    if (user.free_transcriptions_used >= 100) {
      return 429 { error: "Limite free atingido", upgrade_url: "..." }
    }
  }

  // 3. Verificar feature gating
  const { mode } = req.body
  if (user.plan === 'free' && !['text', 'code'].includes(mode)) {
    return 403 { error: "Modo disponível apenas no Pro" }
  }

  // 4. Chamar Gemini API (com SUA key)
  const geminiResponse = await callGemini({
    audio: req.body.audio,
    systemPrompt: buildPrompt(mode, language),
    thinkingBudget: 0
  })

  // 5. Incrementar contador de uso
  await incrementUsage(user.id, mode)

  // 6. Retornar resultado
  return 200 { text: geminiResponse.text }
}
```

---

## 11. Fluxo Completo do Usuário

```
1. Descobre o VibeFlow (anúncio, SEO, indicação)
2. Acessa site → Baixa para Mac ou Windows
3. Instala → Abre → Tela de cadastro (email + senha)
4. Faz cadastro → Plano Free automático
5. Setup Wizard: permissões, teste de gravação, idiomas
6. Usa Text + Code mode, 100 transcrições/mês grátis
7. Tenta usar Email mode → Modal "Recurso Pro"
8. Chega em 80 transcrições → Notificação "20 restantes"
9. Clica "Assinar Pro" → Checkout Eduzz (PIX/cartão)
10. Paga → Webhook Eduzz → Supabase atualiza plano → Tudo liberado
11. Usa ilimitado com todos os 5 modos
12. Se cancela → Webhook → Volta ao Free no final do período
```

---

## 12. Custos Operacionais Estimados

### Com 100 usuários (início)
| Item | Custo/mês |
|------|-----------|
| Supabase (free tier) | R$0 |
| Gemini API (~50 Pro + 50 Free) | ~R$80 |
| Domínio | ~R$3 |
| **Total** | **~R$83** |
| **Receita (50 Pro × R$19,90)** | **R$995** |
| **Lucro** | **~R$912** |

### Com 500 usuários (crescimento)
| Item | Custo/mês |
|------|-----------|
| Supabase (Pro, se necessário) | ~R$150 |
| Gemini API (~250 Pro + 250 Free) | ~R$400 |
| **Total** | **~R$550** |
| **Receita (250 Pro × R$19,90)** | **R$4.975** |
| **Lucro** | **~R$4.425** |

### Com 1000 usuários
| Item | Custo/mês |
|------|-----------|
| Supabase Pro | ~R$150 |
| Gemini API | ~R$800 |
| **Total** | **~R$950** |
| **Receita (500 Pro × R$19,90)** | **R$9.950** |
| **Lucro** | **~R$9.000** |

---

## 13. Decisões Técnicas Tomadas

| Decisão | Motivo |
|---------|--------|
| Gemini 2.5 Flash (não 2.0) | 2.0 descontinuado em março 2026 |
| thinkingBudget: 0 | Elimina latência do thinking, mantém inteligência |
| REST direto (não SDK) | SDK Swift deprecado, não suporta thinkingConfig |
| Supabase (não Firebase) | Free tier generoso, Edge Functions, PostgreSQL |
| Eduzz (não Stripe) | Melhor para público BR, confiança da audiência |
| Tauri (não Electron) | 10MB vs 150MB, 30MB RAM vs 300MB, Rust seguro |
| 100 free/mês (não palavras) | Mais simples de implementar e entender |

---

## 14. Concorrência

| App | Preço | Plataforma | Free Tier | Diferencial |
|-----|-------|------------|-----------|-------------|
| **Glaido** | $20/mês (~R$120) | macOS only | 2K palavras/semana | Agent Mode (beta) |
| **VibeFlow** | R$19,90/mês | Mac + Windows | 100 transcrições/mês | 5 modos, Code mode, Style Learning, PT nativo |

### Vantagens competitivas do VibeFlow
1. **6x mais barato** que Glaido
2. **Windows** (Glaido é só Mac)
3. **5 modos especializados** (Code, Text, Email, UX, Command)
4. **Português nativo** (UI, prompts, suporte)
5. **Style learning** (IA aprende seu estilo)
6. **Gamificação** (engajamento)

---

## 15. Arquivos Modificados na v2.3.0

| Arquivo | Mudança |
|---------|---------|
| Sources/GeminiService.swift | Reescrito: SDK → REST direto com thinkingBudget: 0 |
| Sources/AppVersion.swift | 2.2.0 → 2.3.0, build 20260217 |
| Package.swift | Removida dependência GoogleGenerativeAI |
| Info.plist | 2.2.0 → 2.3.0 |
| CLAUDE.md | Versão padronizada para 2.3.0 |
| ARCHITECTURE.md | Versão + modelo atualizado |
| CHANGELOG.md | Nova entrada 2.3.0 |
| ANALISE_DE_CUSTOS.md | Modelo atualizado para 2.5 Flash |
| SetupWizardView.swift | URL de validação atualizada |

---

## 16. Integração Eduzz — Padrão Existente (PicElevate)

> Baseado na integração já funcional do projeto PicElevate.
> Token Eduzz: Personal Access Token (permanente, não expira).
> Documentação de referência: `picelevate---product-ai/docs/`

### Padrão de verificação (já funciona no PicElevate)

```
1. Usuário cria conta (email obrigatório, CPF opcional para VibeFlow)
2. Clica "Verificar Compra" ou faz login
3. Backend chama API Eduzz com email do usuário
4. Eduzz retorna lista de compras ativas
5. Backend mapeia Product ID → plano (free/pro)
6. Cria/atualiza registro em user_subscriptions
7. App verifica status antes de cada transcrição
```

### API Eduzz — Endpoints necessários

| Rota | Método | Função |
|------|--------|--------|
| `/api/eduzz/verify` | POST | Verifica compra do usuário na Eduzz |
| `/api/eduzz/subscription` | GET | Retorna assinatura ativa |
| `/api/eduzz/usage` | GET | Histórico de uso |

### Mapeamento de Produtos VibeFlow na Eduzz

```typescript
const VIBEFLOW_PRODUCTS = {
    // Pro Mensal - R$19,90/mês
    'PRODUCT_ID_MENSAL': {
        plan: 'pro',
        name: 'VibeFlow Pro Mensal',
        features: ['all_modes', 'all_languages', 'clarify_text',
                   'style_learning', 'snippets', 'full_history',
                   'full_analytics', 'custom_shortcuts'],
        transcriptions_monthly: -1,  // ilimitado
        price: 19.90
    },

    // Pro Anual - R$14,90/mês (R$178,80/ano)
    'PRODUCT_ID_ANUAL': {
        plan: 'pro_annual',
        name: 'VibeFlow Pro Anual',
        features: ['all_modes', 'all_languages', 'clarify_text',
                   'style_learning', 'snippets', 'full_history',
                   'full_analytics', 'custom_shortcuts'],
        transcriptions_monthly: -1,  // ilimitado
        price: 14.90
    }
};
```

### Diferenças PicElevate → VibeFlow

| Aspecto | PicElevate | VibeFlow |
|---------|------------|----------|
| Verificação | CPF + Email | Email (CPF opcional) |
| Recurso consumido | Créditos (imagens) | Transcrições (contador) |
| Backend | Express + SQLite | Supabase Edge Functions + PostgreSQL |
| Frontend | React (web) | Swift (Mac) / Tauri React (Windows) |
| Planos | 3 tiers (Starter, Pro, Premium) | 2 tiers (Free, Pro) |
| BYOK fallback | Sim (playground free) | Não (API key fica no server) |

### Variáveis de ambiente necessárias (Supabase)

```env
# Eduzz
EDUZZ_ACCESS_TOKEN=edzpap_xxx...
EDUZZ_PRODUCT_ID_MENSAL=XXXXXXX-1
EDUZZ_PRODUCT_ID_ANUAL=XXXXXXX-2

# Gemini
GEMINI_API_KEY=AIzaSy...

# Supabase (auto-configurado)
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=xxx
SUPABASE_SERVICE_ROLE_KEY=xxx
```

### Checklist para criar na Eduzz

- [ ] Criar produto "VibeFlow" na Eduzz
- [ ] Criar variação 1: Pro Mensal (R$19,90/mês, recorrente)
- [ ] Criar variação 2: Pro Anual (R$178,80/ano, recorrente)
- [ ] Anotar Product IDs de cada variação
- [ ] Configurar página de checkout
- [ ] Criar cupom de 100% para teste
- [ ] Testar compra e verificação

---

## 17. Credenciais Configuradas

### Supabase (CRIADO em 2026-02-17)
```
Projeto: vibeflow
Project URL: https://bvdbpyjudmkkspcxevlp.supabase.co
Project ref: bvdbpyjudmkkspcxevlp
Região: West EU (Ireland) - eu-west-1
anon key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ2ZGJweWp1ZG1ra3NwY3hldmxwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzNDA2MzMsImV4cCI6MjA4NjkxNjYzM30.hRaoAXKTesJarVvg8cBky2Umtb1R7R824gJwgEle77w
service_role key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ2ZGJweWp1ZG1ra3NwY3hldmxwIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTM0MDYzMywiZXhwIjoyMDg2OTE2NjMzfQ.DKQ7j_XIg8bUi6wRfMiaCsVbN_l6Cqvv0gIwM5OuRoM
Database password: (gerada automaticamente — ver Settings → Database)
```

### Eduzz (PENDENTE)
```
Access Token: PENDENTE
Product ID Mensal: PENDENTE
Product ID Anual: PENDENTE
```

### Google OAuth (PENDENTE)
```
Google Client ID: PENDENTE
Google Client Secret: PENDENTE
Configurado no Supabase: PENDENTE
```

### Gemini API (JÁ EXISTE no app)
```
API Key: Usar a key existente no Config.swift do usuário
```

---

## 18. Status de Implementação Fase 1

| Passo | Descrição | Status |
|-------|-----------|--------|
| 1.1 | Criar projeto Supabase | ✅ FEITO |
| 1.2 | Copiar credenciais | ✅ FEITO |
| 2.1 | Ativar Email Auth | ⏳ PENDENTE (verificar no dashboard) |
| 3.1 | Criar Google OAuth credentials | ⏳ PENDENTE |
| 3.2 | Configurar Google no Supabase | ⏳ PENDENTE |
| 4.1 | Criar produto VibeFlow na Eduzz | ⏳ PENDENTE |
| 4.2 | Criar variação Pro Mensal | ⏳ PENDENTE |
| 4.3 | Criar variação Pro Anual | ⏳ PENDENTE |
| 4.4 | Pegar Access Token Eduzz | ⏳ PENDENTE |
| 5.1 | Instalar Supabase CLI | ⏳ PENDENTE |
| 5.2 | Inicializar projeto localmente | ⏳ PENDENTE |
| 5.3 | Criar migrations SQL (tabelas) | ⏳ PENDENTE |
| 5.4 | Criar Edge Function /transcribe | ⏳ PENDENTE |
| 5.5 | Criar Edge Function /verify-purchase | ⏳ PENDENTE |
| 5.6 | Criar Edge Function /webhook-eduzz | ⏳ PENDENTE |
| 5.7 | Deploy no Supabase remoto | ⏳ PENDENTE |

### Próximo passo técnico
Instalar Supabase CLI, inicializar projeto, criar migrations e Edge Functions.
As Edge Functions que serão criadas:

1. **`/transcribe`** — Core do produto
   - Recebe: JWT + audio (base64) + mode + language
   - Valida auth → verifica plano → chama Gemini 2.5 Flash (thinkingBudget:0) → retorna texto
   - Free: 100 transcrições/mês, só text+code, PT+EN
   - Pro: ilimitado, todos modos, todos idiomas

2. **`/verify-purchase`** — Verificação Eduzz
   - Recebe: JWT
   - Pega email do usuário → consulta API Eduzz → mapeia product ID → atualiza plano no banco
   - Chamado ao abrir o app / fazer login

3. **`/webhook-eduzz`** — Webhook automático
   - Recebe: payload da Eduzz (compra/cancelamento)
   - Atualiza status da assinatura no banco em tempo real

### Tabelas SQL que serão criadas

```sql
-- 1. profiles (extends auth.users)
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    name TEXT,
    plan TEXT DEFAULT 'free' CHECK (plan IN ('free', 'pro')),
    subscription_status TEXT DEFAULT 'inactive' CHECK (subscription_status IN ('active', 'inactive', 'cancelled', 'expired')),
    eduzz_product_id TEXT,
    transcriptions_used INTEGER DEFAULT 0,
    transcriptions_reset_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. subscriptions
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    plan TEXT NOT NULL CHECK (plan IN ('pro_monthly', 'pro_annual')),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired', 'past_due')),
    eduzz_transaction_id TEXT,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. transcription_log
CREATE TABLE transcription_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    mode TEXT NOT NULL,
    audio_duration_seconds REAL,
    output_length INTEGER,
    language TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Feature gating (lógica no proxy /transcribe)

```
FREE:
  - Modos: text, code
  - Idiomas: pt, en
  - Limite: 100 transcrições/mês
  - Clarify text: NÃO
  - Style learning: NÃO

PRO:
  - Modos: text, code, email, ux_design, command
  - Idiomas: todos (15+)
  - Limite: ilimitado
  - Clarify text: SIM
  - Style learning: SIM
```

---

**Última atualização:** 2026-02-17
**Status:** Supabase criado. Próximo: instalar CLI e implementar backend.
**Referência Eduzz:** Padrão testado no PicElevate (docs/ no projeto picelevate---product-ai)
