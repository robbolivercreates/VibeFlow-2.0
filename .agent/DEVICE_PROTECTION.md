# VoxAiGo — Device-Based Abuse Protection

**Implementado em:** 2026-02-19
**Versão:** 3.0.0
**Status:** ✅ Em produção

---

## Visão Geral

O sistema de proteção por dispositivo impede que usuários criem múltiplas contas gratuitas para contornar o limite de 100 transcrições/mês. A proteção é **silenciosa** — o usuário legítimo nunca vê nenhuma mensagem de erro ou fricção extra.

---

## Como Funciona

### 1. Geração do Device ID (Mac)

**Arquivo:** `Sources/VibeFlow/Managers/DeviceManager.swift`

- Na primeira execução, gera um UUID aleatório
- Salvo no **Keychain** do macOS (persiste mesmo após reinstalação do app)
- Não usa hardware serial para respeitar privacidade, mas é suficientemente persistente para detectar abuso
- Acessível via `DeviceManager.shared.deviceID`

```swift
// UUID único por dispositivo, persistido no Keychain
let deviceID = DeviceManager.shared.deviceID
// Exemplo: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
```

### 2. Envio nas Requisições

**Arquivo:** `Sources/VibeFlow/Managers/SupabaseService.swift`

Todas as requisições para o Supabase incluem o header:

```
X-Device-ID: A1B2C3D4-E5F6-7890-ABCD-EF1234567890
```

Enviado em:
- `sendRequest()` — transcrições de áudio
- `detectAndTranslate()` — traduções de texto (Conversation Reply)

### 3. Detecção de Abuso no Servidor

**Arquivo:** `supabase/functions/transcribe/index.ts`

A Edge Function executa a seguinte verificação antes de cada transcrição:

```typescript
// Busca outros user_ids que usaram este device nos últimos 30 dias
const distinctOtherAccounts = new Set(
  deviceRows?.map(r => r.user_id) ?? []
).size;

// Se 2+ outras contas usaram este dispositivo → força Free
if (distinctOtherAccounts >= DEVICE_ABUSE_THRESHOLD) {
  effectivePlan = "free";
}
```

**Threshold:** 2 contas diferentes além da atual (`DEVICE_ABUSE_THRESHOLD = 2`)

### 4. Registro no Banco de Dados

**Tabela:** `usage_log`
**Coluna adicionada:** `device_id TEXT`

Cada transcrição registra o device ID no log, permitindo:
- Histórico de uso por dispositivo
- Auditoria de abuso
- Ajuste futuro do threshold

---

## Fluxo de Decisão

```
Requisição de transcrição chega
          │
          ▼
Lê X-Device-ID do header
          │
          ▼
Busca no usage_log:
"Quantas contas diferentes usaram este device nos últimos 30 dias?"
          │
    ┌─────┴──────┐
    │            │
  < 2        ≥ 2 contas
    │            │
    ▼            ▼
Plano real   Força "free"
(free/pro)   (independente do plano real)
    │            │
    └─────┬──────┘
          │
          ▼
Processa transcrição com o plano efetivo
```

---

## Cenários

### Usuário legítimo (1 conta, 1 Mac)
- Device ID enviado → 0 outras contas no log → plano real aplicado ✅

### Usuário com 2 Macs (legítimo)
- Cada Mac tem um device ID diferente → sem interferência ✅

### Abusador (3 contas no mesmo Mac)
- Conta 1: 0 outras → plano real (pode ser free ou pro)
- Conta 2: 1 outra → ainda OK
- Conta 3: 2 outras → **forçado para free** silenciosamente 🚫

### App sem device ID (versão antiga ou Windows futuro)
- Header ausente → `deviceId = null` → verificação pulada → plano real aplicado
- (Windows implementará o mesmo sistema quando desenvolvido)

---

## Parâmetros Configuráveis

| Parâmetro | Valor atual | Onde alterar |
|-----------|-------------|--------------|
| Threshold de contas | 2 | `transcribe/index.ts` linha `DEVICE_ABUSE_THRESHOLD` |
| Janela de tempo | 30 dias | `transcribe/index.ts` linha `thirtyDaysAgo` |

---

## Banco de Dados

### Migration aplicada

```sql
ALTER TABLE usage_log ADD COLUMN IF NOT EXISTS device_id TEXT;
CREATE INDEX IF NOT EXISTS idx_usage_log_device_id ON usage_log(device_id);
```

### Query de auditoria (verificar dispositivos suspeitos)

```sql
SELECT
  device_id,
  COUNT(DISTINCT user_id) as contas_distintas,
  COUNT(*) as total_transcricoes,
  MIN(created_at) as primeiro_uso,
  MAX(created_at) as ultimo_uso
FROM usage_log
WHERE device_id IS NOT NULL
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY device_id
HAVING COUNT(DISTINCT user_id) >= 2
ORDER BY contas_distintas DESC;
```

---

## Limitações Conhecidas

1. **Keychain pode ser apagado manualmente** — usuário avançado pode deletar o Keychain e obter um novo device ID. Mitigação futura: usar hardware serial via IOKit.

2. **Máquinas virtuais** — VMs podem compartilhar Keychains. Caso raro e aceitável.

3. **Sem cobertura no Windows** — a versão Windows (Tauri, Phase 3) deverá implementar o equivalente usando o registro do sistema ou arquivo persistente.

4. **Sem notificação ao usuário** — o usuário abusador simplesmente vê features de Free sem saber o motivo. Decisão intencional para não revelar o mecanismo.

---

## Próximas Melhorias (Futuro)

- [ ] Usar `IOPlatformSerialNumber` para device ID mais robusto (requer entitlements)
- [ ] Dashboard administrativo para ver dispositivos suspeitos
- [ ] Limite de 2 sessões simultâneas para contas Pro
- [ ] Rate limiting por IP no Supabase Edge Function
- [ ] Implementar equivalente no app Windows (Tauri)
