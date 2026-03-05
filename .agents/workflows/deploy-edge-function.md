---
description: how to deploy Supabase Edge Functions correctly
---

# Deploy Supabase Edge Function

## CRITICAL: Always use `--no-verify-jwt`

The Supabase API Gateway rejects tokens signed with ES256 (which GoTrue v2.187.0+ generates).
The Edge Function verifies auth internally via REST API, so gateway JWT verification must be disabled.

## Deploy Command

```bash
cd "/Users/robsonoliveira/Library/Mobile Documents/com~apple~CloudDocs/VideoCode2026/VibeFlow 2.0/VibeFlow-2.0"
```

// turbo
```bash
supabase functions deploy transcribe --no-verify-jwt
```

## What Happened (March 5, 2026)

### Root Cause
Supabase GoTrue updated to v2.187.0 which started signing JWT tokens with **ES256** algorithm 
instead of **HS256**. The Supabase API Gateway (Kong/Envoy) still validates JWTs using the 
project's HS256 secret. This mismatch causes the gateway to reject ALL requests with 
`{"code":401,"message":"Invalid JWT"}` BEFORE the Edge Function code even executes.

### Symptoms
- App shows "Erro: Session expired..." on every transcription attempt
- Supabase Edge Functions Invocations dashboard shows 100% 401 errors
- Logging / debug code inside the Edge Function NEVER appears (gateway blocks before function runs)
- Login works fine, user appears as authenticated in the app
- Happens on ALL devices, not just one

### Fix
1. Deploy with `--no-verify-jwt` flag to skip gateway JWT validation
2. The Edge Function verifies tokens internally via direct REST API call to `/auth/v1/user`

### What NOT to do
- Do NOT deploy without `--no-verify-jwt` — it will break immediately
- Do NOT use `thinkingBudget: 0` with gemini-2.5-flash (causes 400 errors)
- Do NOT use `thinkingLevel: "minimal"` with gemini-2.5-flash (only works with 3.1+)

## Current Stack (after fix)
- **Model:** gemini-3.1-flash-lite-preview
- **Thinking:** Per-mode levels (minimal → high)
- **Grounding:** Google Search enabled for `ux_design` mode only
- **Auth:** REST API verification inside function (bypassing gateway)
