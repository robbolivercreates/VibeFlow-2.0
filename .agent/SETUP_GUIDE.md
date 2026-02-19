# VibeFlow — Setup Manual (Passo a Passo)

> Execute cada passo na ordem. Ao final, me traga os resultados marcados com 📋.

---

## PARTE 1: Criar Projeto Supabase

### Passo 1.1 — Criar conta/projeto
1. Acesse https://supabase.com
2. Clique "Start your project"
3. Faça login com **GitHub**
4. Clique "New project"
5. Preencha:
   - **Organization:** Selecione sua org (ou crie uma)
   - **Name:** `vibeflow`
   - **Database Password:** Crie uma senha forte e ANOTE
   - **Region:** `South America (São Paulo)` — sa-east-1
   - **Pricing Plan:** Free
6. Clique "Create new project"
7. Aguarde ~2 minutos até o projeto estar pronto

### Passo 1.2 — Copiar credenciais
1. No dashboard do projeto, vá em **Settings** (engrenagem no menu lateral)
2. Clique em **API** (dentro de Settings)
3. Copie e anote:

📋 **RESULTADO 1 — Credenciais Supabase:**
```
Project URL: https://xxxxxxxxxx.supabase.co
anon (public) key: eyJhbGci...
service_role (secret) key: eyJhbGci...
Project ref (da URL): xxxxxxxxxx
Database password: (a que você criou)
```

---

## PARTE 2: Ativar Autenticação por Email

### Passo 2.1 — Verificar Email Auth
1. No menu lateral, vá em **Authentication**
2. Clique em **Providers**
3. **Email** já deve estar ativado por padrão
4. Confirme que está com toggle ON
5. Em "Confirm email" → pode deixar **desativado** para facilitar testes (ativa depois)

📋 **RESULTADO 2:** Email Auth está ativado? (Sim/Não)

---

## PARTE 3: Ativar Google OAuth

### Passo 3.1 — Criar credenciais no Google Cloud
1. Acesse https://console.cloud.google.com
2. Crie um novo projeto ou selecione um existente
3. Vá em **APIs & Services** → **Credentials**
4. Clique **"+ CREATE CREDENTIALS"** → **"OAuth client ID"**
5. Se pedir para configurar a "Consent Screen":
   - User Type: **External**
   - App name: **VibeFlow**
   - User support email: seu email
   - Developer contact: seu email
   - Clique "Save and Continue" em todas as etapas
6. Volte em **Credentials** → **"+ CREATE CREDENTIALS"** → **"OAuth client ID"**
7. Preencha:
   - Application type: **Web application**
   - Name: **VibeFlow Supabase**
   - Authorized redirect URIs: Adicione:
     ```
     https://XXXXXXXXXX.supabase.co/auth/v1/callback
     ```
     (substitua XXXXXXXXXX pelo seu Project ref do Passo 1.2)
8. Clique "Create"
9. Copie o **Client ID** e **Client Secret**

📋 **RESULTADO 3 — Google OAuth:**
```
Google Client ID: xxxxxxxxxxxx.apps.googleusercontent.com
Google Client Secret: GOCSPX-xxxxxxxxxxxx
```

### Passo 3.2 — Configurar Google no Supabase
1. Volte ao dashboard do Supabase
2. Vá em **Authentication** → **Providers**
3. Encontre **Google** e clique para expandir
4. Ative o toggle
5. Cole:
   - **Client ID**: o que copiou no passo 3.1
   - **Client Secret**: o que copiou no passo 3.1
6. Clique **Save**

📋 **RESULTADO 4:** Google OAuth configurado no Supabase? (Sim/Não)

---

## PARTE 4: Criar Produto na Eduzz

### Passo 4.1 — Criar produto VibeFlow
1. Acesse https://eduzz.com (ou https://console.eduzz.com)
2. Vá em **"Meus Produtos"** → **"Criar Produto"**
3. Preencha:
   - **Nome:** VibeFlow Pro
   - **Tipo:** Produto Digital / Assinatura (recorrente)
   - **Descrição:** Transcrição por voz com IA — ilimitado para assinantes

### Passo 4.2 — Criar variação Pro Mensal
1. Crie uma variação/oferta:
   - **Nome:** VibeFlow Pro Mensal
   - **Preço:** R$19,90/mês
   - **Tipo de cobrança:** Recorrente/Assinatura
   - **Período:** Mensal
2. Anote o **Product ID** desta variação

### Passo 4.3 — Criar variação Pro Anual
1. Crie outra variação/oferta:
   - **Nome:** VibeFlow Pro Anual
   - **Preço:** R$178,80/ano (equivale a R$14,90/mês)
   - **Tipo de cobrança:** Recorrente/Assinatura
   - **Período:** Anual
2. Anote o **Product ID** desta variação

### Passo 4.4 — Pegar Access Token
1. Acesse https://console.eduzz.com
2. Vá em **"Meus Aplicativos"**
3. Se já tem o app PicElevate, pode reutilizar o mesmo token
4. Ou crie novo app:
   - Nome: VibeFlow
   - Escopos: `myeduzz_financial_read`, `myeduzz_customers_read`, `myeduzz_subscriptions_read`
5. Gere o **Personal Access Token**

📋 **RESULTADO 5 — Eduzz:**
```
Access Token: edzpap_xxx...
Product ID Mensal: XXXXXXX-1
Product ID Anual: XXXXXXX-2
Link de checkout Mensal: https://...
Link de checkout Anual: https://...
```

### Passo 4.5 — Criar cupom de teste (opcional mas recomendado)
1. Na Eduzz, vá em **Cupons**
2. Crie um cupom com **100% de desconto**
3. Nome: VIBEFLOW-TESTE
4. Limite: 5 usos
5. Isso permite testar o fluxo completo sem pagar

📋 **RESULTADO 6:** Cupom de teste criado? Código: ____________

---

## PARTE 5: Gemini API Key

### Passo 5.1 — Pegar sua API Key
1. Acesse https://aistudio.google.com/apikey
2. Copie sua API Key existente ou crie uma nova
3. Esta key ficará APENAS no servidor (usuário nunca verá)

📋 **RESULTADO 7 — Gemini:**
```
Gemini API Key: AIzaSy...
```

---

## RESUMO — O que me trazer de volta

Quando terminar, me passe estes 7 resultados:

```
=== SUPABASE ===
Project URL:
anon key:
service_role key:
Project ref:

=== GOOGLE OAUTH ===
Google Client ID:
Google Client Secret:
Google OAuth configurado no Supabase: Sim/Não

=== EDUZZ ===
Access Token:
Product ID Mensal:
Product ID Anual:
Link de checkout Mensal:
Link de checkout Anual:

=== GEMINI ===
API Key:

=== AUTH ===
Email Auth ativado: Sim/Não
Cupom de teste:
```

Com essas informações eu implemento TODO o backend de uma vez:
- Tabelas do banco
- Edge Function de transcrição (proxy Gemini)
- Edge Function de verificação Eduzz
- Edge Function de webhook
- Configuração de auth
- Deploy completo

---

**Tempo estimado para completar este guia:** 15-20 minutos
**Depois de me trazer os resultados:** Eu implemento o backend completo
