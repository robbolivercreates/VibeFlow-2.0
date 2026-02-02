# 🧮 Calculadora de Custos - VibeFlow

## Fórmulas de Cálculo

### Custo por Requisição

```
Áudio Tokens = Duração (segundos) × 33.33 tokens/segundo
Text Input Tokens = System Prompt (~1000) + User Prompt (~20) = ~1020 tokens
Output Tokens = Tamanho da resposta (estimado: 200 tokens)

Custo = (Áudio Tokens × $0.70/1M) + 
        (Text Input Tokens × $0.10/1M) + 
        (Output Tokens × $0.40/1M)
```

### Exemplo Prático

**Gravação de 30 segundos:**
```
Áudio: 30 × 33.33 = 1.000 tokens
Input Text: 1.020 tokens
Output: 200 tokens

Custo = (1.000 × $0.70/1M) + (1.020 × $0.10/1M) + (200 × $0.40/1M)
      = $0.0007 + $0.000102 + $0.00008
      = $0.000882
      ≈ $0.0009 por requisição
```

---

## Tabela de Custos por Duração

| Duração | Áudio Tokens | Custo Áudio | Custo Total | Custo em R$* |
|---------|--------------|-------------|-------------|--------------|
| 10 seg | 333 | $0.00023 | $0.0004 | R$ 0.002 |
| 15 seg | 500 | $0.00035 | $0.0005 | R$ 0.0025 |
| 30 seg | 1.000 | $0.00070 | $0.0009 | R$ 0.0045 |
| 45 seg | 1.500 | $0.00105 | $0.0013 | R$ 0.0065 |
| 60 seg | 2.000 | $0.00140 | $0.0017 | R$ 0.0085 |
| 90 seg | 3.000 | $0.00210 | $0.0025 | R$ 0.0125 |
| 120 seg | 4.000 | $0.00280 | $0.0033 | R$ 0.0165 |

*Cotização USD: R$ 5.00 (aproximado)

---

## Custo Mensal Estimado

### Por Número de Requisições

| Requisições/Dia | Requisições/Mês | Duração Média | Custo Mensal (USD) | Custo Mensal (R$) |
|-----------------|-----------------|---------------|-------------------|-------------------|
| 10 | 300 | 30 seg | $0.27 | R$ 1.35 |
| 25 | 750 | 30 seg | $0.68 | R$ 3.40 |
| 50 | 1.500 | 30 seg | $1.35 | R$ 6.75 |
| 100 | 3.000 | 30 seg | $2.70 | R$ 13.50 |
| 200 | 6.000 | 30 seg | $5.40 | R$ 27.00 |
| 500 | 15.000 | 30 seg | $13.50 | R$ 67.50 |

### Por Duração Média

| Duração Média | 100 req/dia | 200 req/dia | 500 req/dia |
|---------------|-------------|-------------|-------------|
| 15 seg | $0.15/mês | $0.30/mês | $0.75/mês |
| 30 seg | $0.27/mês | $0.54/mês | $1.35/mês |
| 60 seg | $0.51/mês | $1.02/mês | $2.55/mês |
| 90 seg | $0.75/mês | $1.50/mês | $3.75/mês |

---

## Limite do Tier Gratuito

### Google Gemini Free Tier

- **1.500 requisições/dia** = GRATUITO
- **1M tokens/minuto** = GRATUITO

### Quando Você Paga

| Uso Diário | Status | Custo |
|------------|--------|-------|
| < 1.500 req/dia | ✅ GRATUITO | $0.00 |
| > 1.500 req/dia | ⚠️ COBRADO | $0.0009 × (req - 1.500) |

**Exemplo:**
- 2.000 requisições/dia
- 500 requisições pagas
- Custo: 500 × $0.0009 = **$0.45/dia** = **$13.50/mês**

---

## Economia com Otimizações

### Redução de Sample Rate (44.1kHz → 22kHz)

| Duração Original | Tokens Original | Tokens Otimizado | Economia |
|-----------------|----------------|------------------|----------|
| 30 seg | 1.000 | 700 | 30% |
| 60 seg | 2.000 | 1.400 | 30% |

**Economia mensal (100 req/dia, 30 seg):**
- Antes: $0.27/mês
- Depois: $0.19/mês
- **Economia: $0.08/mês (30%)**

### Limite de Duração Máxima (2 minutos)

**Antes:** Gravações de até 5 minutos = 5.000 tokens  
**Depois:** Limite de 2 minutos = 2.000 tokens

**Economia:** 60% em gravações longas

---

## Comparação: VibeFlow vs Alternativas

### Custo para 1.000 minutos de áudio/mês

| Serviço | Custo Mensal | Observações |
|---------|--------------|-------------|
| **VibeFlow (Gemini)** | $1.40 | ✅ Processamento inteligente |
| OpenAI Whisper | $6.00 | Apenas transcrição |
| AssemblyAI | $4.17 | Apenas transcrição |
| Deepgram | $7.17 | Apenas transcrição |

**VibeFlow é mais barato E oferece mais funcionalidades!**

---

## Dicas para Reduzir Custos

1. ✅ **Use o tier gratuito** (até 1.500 req/dia)
2. ✅ **Mantenha gravações curtas** (< 60 segundos)
3. ✅ **Evite gravações muito longas** (> 2 minutos)
4. ✅ **Use modos específicos** (reduz output tokens)
5. ✅ **Monitore seu uso diário**

---

**Última Atualização:** 8 de Janeiro de 2025
