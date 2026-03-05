# Sistema de Licenciamento VibeFlow

## 🎯 Arquitetura

```
[Cliente] → [App VibeFlow] → [Servidor de Licenças] → [Banco de Dados]
                ↓
         [License Key] ← [Gumroad/LemonSqueezy]
```

## 🔐 Fluxo de Ativação

1. **Usuário compra** no site (Gumroad/LemonSqueezy)
2. **Recebe email** com License Key (ex: `VIBE-XXXX-XXXX-XXXX`)
3. **Abre o app** pela primeira vez
4. **Insere a key** na tela de ativação
5. **App valida** com servidor
6. **Libera uso** se válida

## 📋 Estrutura da License Key

Formato: `VIBE-XXXX-XXXX-XXXX` (16 caracteres)

Exemplo: `VIBE-A7B3-C9D2-E4F1`

## 🛠️ Componentes

### 1. Servidor de Licenças (Simples)
- Node.js + Express
- SQLite (banco leve)
- Deploy: Railway/Render (gratuito)

### 2. Endpoints
```
POST /api/activate
  Body: { key: "VIBE-XXXX", machine_id: "abc123" }
  Response: { valid: true, expires: null }

POST /api/verify
  Body: { key: "VIBE-XXXX", machine_id: "abc123" }
  Response: { valid: true }
```

### 3. No App (Swift)
- Tela de ativação no primeiro uso
- Salvar key ativada localmente (Keychain)
- Verificar online periodicamente

## 💰 Plataformas de Venda

| Plataforma | Taxa | Recursos |
|------------|------|----------|
| **Gumroad** | 10% + processamento | Simples, boa conversão |
| **LemonSqueezy** | 5% + 50¢ | Melhor para SaaS |
| **Stripe** | 2.9% + 30¢ | Mais controle, mais trabalho |

**Recomendação:** Gumroad para começar (mais fácil)

## 🚀 Plano de Implementação

### Fase 1: Básico (1-2 dias)
- [ ] Criar tela de ativação no app
- [ ] Gerador de license keys
- [ ] Validação offline simples

### Fase 2: Servidor (2-3 dias)
- [ ] API de ativação
- [ ] Banco de dados de licenças
- [ ] Deploy do servidor

### Fase 3: Integração (1 dia)
- [ ] Webhook Gumroad
- [ ] Email automático com key
- [ ] DMG installer

## 📄 Preço Sugerido

| Plano | Preço | Inclui |
|-------|-------|--------|
| **Personal** | $29 | 1 Mac, updates 1 ano |
| **Pro** | $49 | 3 Macs, updates vitalícios |
| **Team** | $99 | 10 Macs, updates vitalícios |

## 🔒 Segurança

- Keys geradas criptograficamente
- Machine ID vinculado (evita compartilhamento)
- Verificação online opcional (não bloqueia se offline)

Quer que eu comece implementando? 🚀
