#!/usr/bin/env python3
"""
Calculadora de Custos - VibeFlow
Calcula custos da API Google Gemini 2.0 Flash baseado no uso
"""

# Preços por milhão de tokens (USD)
PRICE_AUDIO_INPUT = 0.70  # $0.70 por 1M tokens
PRICE_TEXT_INPUT = 0.10   # $0.10 por 1M tokens
PRICE_TEXT_OUTPUT = 0.40  # $0.40 por 1M tokens

# Conversão de áudio para tokens (estimativa conservadora)
TOKENS_PER_SECOND = 33.33  # ~33 tokens por segundo de áudio

# Tokens fixos por requisição
SYSTEM_PROMPT_TOKENS = 1000  # System prompt médio
USER_PROMPT_TOKENS = 20       # User prompt fixo
AVERAGE_OUTPUT_TOKENS = 200   # Resposta média

# Limites do tier gratuito
FREE_TIER_DAILY_REQUESTS = 1500
FREE_TIER_TOKENS_PER_MINUTE = 1_000_000


def calcular_custo_por_requisicao(duracao_segundos: float) -> dict:
    """
    Calcula o custo de uma única requisição
    
    Args:
        duracao_segundos: Duração da gravação em segundos
    
    Returns:
        Dicionário com breakdown de custos
    """
    # Calcular tokens
    audio_tokens = int(duracao_segundos * TOKENS_PER_SECOND)
    text_input_tokens = SYSTEM_PROMPT_TOKENS + USER_PROMPT_TOKENS
    output_tokens = AVERAGE_OUTPUT_TOKENS
    
    # Calcular custos
    audio_cost = (audio_tokens / 1_000_000) * PRICE_AUDIO_INPUT
    text_input_cost = (text_input_tokens / 1_000_000) * PRICE_TEXT_INPUT
    output_cost = (output_tokens / 1_000_000) * PRICE_TEXT_OUTPUT
    
    total_cost = audio_cost + text_input_cost + output_cost
    
    return {
        'audio_tokens': audio_tokens,
        'text_input_tokens': text_input_tokens,
        'output_tokens': output_tokens,
        'audio_cost': audio_cost,
        'text_input_cost': text_input_cost,
        'output_cost': output_cost,
        'total_cost': total_cost,
        'total_cost_brl': total_cost * 5.0  # USD para BRL (cotação aproximada)
    }


def calcular_custo_mensal(requisicoes_por_dia: int, duracao_media_segundos: float) -> dict:
    """
    Calcula custo mensal baseado no uso diário
    
    Args:
        requisicoes_por_dia: Número de requisições por dia
        duracao_media_segundos: Duração média das gravações
    
    Returns:
        Dicionário com análise de custos mensais
    """
    requisicoes_mes = requisicoes_por_dia * 30
    custo_por_req = calcular_custo_por_requisicao(duracao_media_segundos)
    
    # Requisições dentro do tier gratuito
    requisicoes_gratuitas = min(requisicoes_por_dia, FREE_TIER_DAILY_REQUESTS)
    requisicoes_pagas = max(0, requisicoes_por_dia - FREE_TIER_DAILY_REQUESTS)
    
    # Custo diário
    custo_diario_gratuito = 0.0
    custo_diario_pago = requisicoes_pagas * custo_por_req['total_cost']
    custo_diario_total = custo_diario_pago
    
    # Custo mensal
    custo_mensal = custo_diario_total * 30
    
    return {
        'requisicoes_por_dia': requisicoes_por_dia,
        'requisicoes_mes': requisicoes_mes,
        'requisicoes_gratuitas': requisicoes_gratuitas,
        'requisicoes_pagas': requisicoes_pagas,
        'custo_por_requisicao': custo_por_req,
        'custo_diario': custo_diario_total,
        'custo_mensal_usd': custo_mensal,
        'custo_mensal_brl': custo_mensal * 5.0,
        'dentro_tier_gratuito': requisicoes_pagas == 0
    }


def imprimir_analise(analise: dict):
    """Imprime análise de custos formatada"""
    print("\n" + "="*60)
    print("📊 ANÁLISE DE CUSTOS - VIBEFLOW")
    print("="*60)
    
    print(f"\n📈 USO:")
    print(f"   Requisições por dia: {analise['requisicoes_por_dia']}")
    print(f"   Requisições por mês: {analise['requisicoes_mes']}")
    print(f"   Duração média: {analise['custo_por_requisicao']['audio_tokens'] / TOKENS_PER_SECOND:.1f} segundos")
    
    print(f"\n💰 CUSTO POR REQUISIÇÃO:")
    print(f"   Áudio: ${analise['custo_por_requisicao']['audio_cost']:.6f} ({analise['custo_por_requisicao']['audio_tokens']} tokens)")
    print(f"   Input Text: ${analise['custo_por_requisicao']['text_input_cost']:.6f} ({analise['custo_por_requisicao']['text_input_tokens']} tokens)")
    print(f"   Output: ${analise['custo_por_requisicao']['output_cost']:.6f} ({analise['custo_por_requisicao']['output_tokens']} tokens)")
    print(f"   TOTAL: ${analise['custo_por_requisicao']['total_cost']:.6f} (R$ {analise['custo_por_requisicao']['total_cost_brl']:.4f})")
    
    print(f"\n📅 CUSTO MENSAL:")
    if analise['dentro_tier_gratuito']:
        print(f"   ✅ DENTRO DO TIER GRATUITO")
        print(f"   Requisições gratuitas: {analise['requisicoes_gratuitas']}/dia")
        print(f"   Custo: $0.00 (GRATUITO)")
    else:
        print(f"   ⚠️ EXCEDE TIER GRATUITO")
        print(f"   Requisições gratuitas: {analise['requisicoes_gratuitas']}/dia")
        print(f"   Requisições pagas: {analise['requisicoes_pagas']}/dia")
        print(f"   Custo diário: ${analise['custo_diario']:.4f} (R$ {analise['custo_diario'] * 5.0:.2f})")
        print(f"   Custo mensal: ${analise['custo_mensal_usd']:.2f} (R$ {analise['custo_mensal_brl']:.2f})")
    
    print("\n" + "="*60)


def main():
    """Função principal - interface interativa"""
    print("\n🧮 CALCULADORA DE CUSTOS - VIBEFLOW")
    print("="*60)
    
    try:
        # Obter inputs do usuário
        print("\n📝 Informe seus dados de uso:")
        req_dia = int(input("   Quantas requisições por dia? "))
        duracao = float(input("   Duração média das gravações (segundos)? "))
        
        # Calcular
        analise = calcular_custo_mensal(req_dia, duracao)
        
        # Imprimir resultado
        imprimir_analise(analise)
        
        # Exemplos adicionais
        print("\n💡 EXEMPLOS DE OUTROS CENÁRIOS:")
        print("-"*60)
        
        exemplos = [
            (10, 30, "Uso pessoal leve"),
            (50, 30, "Uso pessoal moderado"),
            (100, 45, "Uso profissional"),
            (200, 60, "Uso intenso"),
        ]
        
        for req, dur, desc in exemplos:
            ex_analise = calcular_custo_mensal(req, dur)
            status = "✅ GRÁTIS" if ex_analise['dentro_tier_gratuito'] else f"${ex_analise['custo_mensal_usd']:.2f}/mês"
            print(f"   {desc:25} ({req} req/dia, {dur}s): {status}")
        
    except ValueError:
        print("\n❌ Erro: Por favor, insira números válidos")
    except KeyboardInterrupt:
        print("\n\n👋 Até logo!")
    except Exception as e:
        print(f"\n❌ Erro: {e}")


if __name__ == "__main__":
    main()
