# 📊 Análise de Custos - VibeFlow

**Data de Criação:** 8 de Janeiro de 2025  
**Modelo Utilizado:** Google Gemini 2.0 Flash  
**Versão do App:** v1.0

---

## 📋 Sumário Executivo

O VibeFlow utiliza a API do **Google Gemini 2.0 Flash** para processamento de áudio. Este documento detalha:
- Estrutura de preços da API
- Cálculo de custos por uso
- Estimativas de custo mensal
- Comparação com alternativas
- Recomendações de otimização

---

## 💰 Estrutura de Preços do Google Gemini 2.0 Flash

### Preços por Milhão de Tokens (1M tokens)

| Tipo de Token | Custo por 1M Tokens | Custo por 1.000 Tokens |
|---------------|---------------------|------------------------|
| **Áudio Input** | **$0.70** | **$0.00070** |
| Text/Image/Video Input | $0.10 | $0.00010 |
| Text Output | $0.40 | $0.00040 |

### ⚠️ Observação Importante

**Áudio tem preço 7x maior que texto!**  
- Texto input: $0.10/1M tokens
- **Áudio input: $0.70/1M tokens** ← Seu caso

---

## 🎯 Como o VibeFlow Usa a API

### Configuração Atual

```swift
Modelo: gemini-2.5-flash
Temperature: 0.2
Max Output Tokens: 4096
Formato de Áudio: MPEG4 AAC (.m4a)
Sample Rate: 44.1 kHz
Canais: Mono
```

### O Que é Enviado para a API

1. **System Prompt** (instruções do modo)
   - Tamanho típico: ~500-2000 tokens
   - Exemplo: "CODE MODE\nSTRICT RULES:\n1. Output ONLY code..."

2. **User Prompt** (texto)
   - Tamanho: ~20 tokens
   - Texto: "Process the following audio according to your instructions..."

3. **Áudio** (dados binários)
   - Formato: Base64 encoded M4A
   - Tamanho variável baseado na duração da gravação

4. **Output** (resposta do modelo)
   - Máximo: 4096 tokens
   - Tamanho típico: 50-500 tokens

---

## 📐 Cálculo de Custos

### Fórmula de Custo por Requisição

```
Custo Total = (Áudio Input Tokens × $0.70/1M) + 
              (Text Input Tokens × $0.10/1M) + 
              (Output Tokens × $0.40/1M)
```

### Como o Áudio é Convertido em Tokens

O Gemini processa áudio de forma especial:
- **1 minuto de áudio ≈ 1.000-2.000 tokens** (estimativa conservadora)
- Depende da qualidade, sample rate e compressão

**Exemplo de Cálculo:**
- Gravação de 30 segundos
- Áudio: ~500 tokens
- System Prompt: ~1.000 tokens (texto)
- User Prompt: ~20 tokens (texto)
- Output: ~200 tokens

```
Custo = (500 × $0.70/1M) + (1.020 × $0.10/1M) + (200 × $0.40/1M)
      = $0.00035 + $0.000102 + $0.00008
      = $0.000532 por requisição
      ≈ $0.0005 (meio centavo de dólar)
```

---

## 📊 Estimativas de Custo Mensal

### Cenário 1: Uso Pessoal Leve
- **10 gravações/dia** × 30 dias = 300 requisições/mês
- Duração média: 30 segundos
- **Custo estimado: $0.15/mês** (~R$ 0.75/mês)

### Cenário 2: Uso Pessoal Moderado
- **50 gravações/dia** × 30 dias = 1.500 requisições/mês
- Duração média: 45 segundos
- **Custo estimado: $1.05/mês** (~R$ 5.25/mês)

### Cenário 3: Uso Profissional Intenso
- **200 gravações/dia** × 30 dias = 6.000 requisições/mês
- Duração média: 60 segundos
- **Custo estimado: $4.20/mês** (~R$ 21.00/mês)

### Cenário 4: Uso Empresarial
- **1.000 gravações/dia** × 30 dias = 30.000 requisições/mês
- Duração média: 60 segundos
- **Custo estimado: $21.00/mês** (~R$ 105.00/mês)

---

## 🆓 Tier Gratuito do Google Gemini

### Limites do Tier Gratuito (Free Tier)

| Recurso | Limite Gratuito |
|---------|----------------|
| **Requisições por minuto** | 15 RPM |
| **Requisições por dia** | 1.500 RPD |
| **Tokens por minuto** | 1M TPM |
| **Custo** | **$0.00** |

### O Que Isso Significa para Você

✅ **Uso Pessoal Leve/Moderado:** **GRATUITO**  
- Até 1.500 requisições/dia
- Até 1M tokens/minuto
- **Sem custo!**

⚠️ **Uso Profissional/Intenso:** Pode exceder o tier gratuito
- Acima de 1.500 requisições/dia = cobrança
- Acima de 1M tokens/minuto = rate limit

---

## 💡 Comparação com Alternativas

### Google Gemini 2.0 Flash vs Outros

| Serviço | Custo Áudio Input | Custo Output | Observações |
|---------|-------------------|--------------|-------------|
| **Gemini 2.0 Flash** | $0.70/1M tokens | $0.40/1M tokens | ✅ Usado no VibeFlow |
| OpenAI Whisper API | $0.006/minuto | - | Apenas transcrição |
| AssemblyAI | $0.00025/segundo | - | Apenas transcrição |
| Deepgram | $0.0043/minuto | - | Apenas transcrição |

**Nota:** Gemini oferece mais que transcrição - inclui processamento inteligente, tradução, formatação, etc.

---

## 📈 Análise de Custos Detalhada

### Breakdown por Componente

#### 1. System Prompt (Text Input)
- Tamanho: ~1.000 tokens por requisição
- Custo: $0.0001 por requisição
- **Impacto: Baixo** (10% do custo total)

#### 2. User Prompt (Text Input)
- Tamanho: ~20 tokens por requisição
- Custo: $0.000002 por requisição
- **Impacto: Negligível** (<1% do custo total)

#### 3. Áudio Input ⚠️
- Tamanho: ~500-2.000 tokens por minuto de áudio
- Custo: $0.00035 - $0.0014 por minuto
- **Impacto: ALTO** (70-80% do custo total)

#### 4. Output (Text Output)
- Tamanho: ~50-500 tokens por resposta
- Custo: $0.00002 - $0.0002 por requisição
- **Impacto: Baixo** (5-10% do custo total)

### Conclusão da Análise

**O áudio é o maior componente de custo!**  
- Reduzir duração das gravações = redução direta de custos
- Otimizar qualidade de áudio pode reduzir tokens

---

## 🎯 Recomendações de Otimização

### 1. Limitar Duração Máxima de Gravação
```swift
// Sugestão: Adicionar limite de 2 minutos
if recordingDuration > 120 {
    stopRecording()
    showWarning("Gravação muito longa")
}
```
**Economia estimada:** 30-50% em uso intenso

### 2. Comprimir Áudio Antes de Enviar
```swift
// Reduzir sample rate para 22kHz (suficiente para voz)
AVSampleRateKey: 22050.0  // Em vez de 44100.0
```
**Economia estimada:** 20-30% de tokens

### 3. Cache de System Prompts
- Reutilizar prompts idênticos
- **Economia estimada:** 5-10%

### 4. Monitoramento de Uso
- Adicionar contador de requisições
- Alertas quando próximo do limite gratuito
- **Benefício:** Controle de custos

### 5. Batch Processing (Futuro)
- Agrupar múltiplas gravações curtas
- **Economia estimada:** 50% (preço batch é metade)

---

## 📊 Dashboard de Custos (Sugestão de Implementação)

### Métricas a Rastrear

1. **Requisições por dia/semana/mês**
2. **Tokens de áudio processados**
3. **Custo acumulado**
4. **Duração média de gravações**
5. **Modo mais usado**

### Exemplo de Implementação

```swift
class UsageTracker {
    var totalRequests: Int = 0
    var totalAudioTokens: Int = 0
    var totalCost: Double = 0.0
    
    func trackRequest(audioDuration: TimeInterval, outputTokens: Int) {
        let audioTokens = Int(audioDuration * 33.33) // ~33 tokens/segundo
        let cost = calculateCost(audioTokens: audioTokens, outputTokens: outputTokens)
        
        totalRequests += 1
        totalAudioTokens += audioTokens
        totalCost += cost
    }
    
    func calculateCost(audioTokens: Int, outputTokens: Int) -> Double {
        let audioCost = Double(audioTokens) * 0.70 / 1_000_000
        let outputCost = Double(outputTokens) * 0.40 / 1_000_000
        return audioCost + outputCost
    }
}
```

---

## 🚨 Alertas e Limites Recomendados

### Níveis de Alerta

| Nível | Requisições/Dia | Ação |
|-------|-----------------|------|
| 🟢 **Normal** | < 1.000 | Sem ação |
| 🟡 **Atenção** | 1.000 - 1.400 | Notificar usuário |
| 🟠 **Alto** | 1.400 - 1.500 | Aviso de limite gratuito |
| 🔴 **Crítico** | > 1.500 | Bloquear ou avisar sobre cobrança |

---

## 📝 Resumo Final

### Para Uso Pessoal
- ✅ **Custo: $0.00/mês** (dentro do tier gratuito)
- ✅ Até 1.500 requisições/dia
- ✅ Sem preocupações de custo

### Para Uso Profissional
- ⚠️ **Custo: $1-5/mês** (pode exceder tier gratuito)
- ⚠️ Monitorar uso diário
- ⚠️ Considerar otimizações

### Para Uso Empresarial
- 🔴 **Custo: $20-50/mês** (excede tier gratuito)
- 🔴 Implementar monitoramento
- 🔴 Aplicar otimizações recomendadas
- 🔴 Considerar batch processing

---

## 🔗 Referências

- [Google Gemini Pricing](https://ai.google.dev/pricing)
- [Gemini API Documentation](https://ai.google.dev/docs)
- [Token Counting Guide](https://ai.google.dev/gemini-api/docs/tokens)

---

## 📅 Histórico de Versões

| Data | Versão | Mudanças |
|------|--------|----------|
| 2025-01-08 | 1.0 | Documento inicial |

---

**Última Atualização:** 8 de Janeiro de 2025  
**Próxima Revisão:** Quando houver mudanças significativas nos preços da API
