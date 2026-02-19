#!/usr/bin/env python3
"""
Gerador de License Keys para VoxAiGo
Uso: python3 generate_keys.py --count 100 --output keys.txt
"""

import argparse
import secrets
import string
from datetime import datetime


def generate_key():
    """Gera uma license key no formato VOXA-XXXX-XXXX-XXXX"""
    chars = string.ascii_uppercase + string.digits
    # Remove caracteres confusos (0, O, I, 1)
    chars = chars.replace('0', '').replace('O', '').replace('I', '').replace('1', '')

    parts = []
    for _ in range(3):
        part = ''.join(secrets.choice(chars) for _ in range(4))
        parts.append(part)

    return f"VOXA-{ '-'.join(parts) }"


def generate_keys(count: int, prefix: str = ""):
    """Gera múltiplas keys únicas"""
    keys = set()
    while len(keys) < count:
        key = generate_key()
        if prefix:
            key = f"{prefix}-{key}"
        keys.add(key)
    return list(keys)


def main():
    parser = argparse.ArgumentParser(description='Gerador de License Keys VoxAiGo')
    parser.add_argument('--count', '-c', type=int, default=100, help='Quantidade de keys')
    parser.add_argument('--output', '-o', type=str, default='license_keys.txt', help='Arquivo de saída')
    parser.add_argument('--prefix', '-p', type=str, default='', help='Prefixo (ex: PRO, TEAM)')

    args = parser.parse_args()

    print(f"🎫 Gerando {args.count} license keys...")

    keys = generate_keys(args.count, args.prefix)

    # Salvar em arquivo
    with open(args.output, 'w') as f:
        f.write(f"# VoxAiGo License Keys\n")
        f.write(f"# Gerado em: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"# Total: {len(keys)}\n")
        f.write(f"# Formato: VOXA-XXXX-XXXX-XXXX\n\n")

        for i, key in enumerate(keys, 1):
            f.write(f"{key}\n")

    print(f"✅ {len(keys)} keys geradas!")
    print(f"📁 Salvo em: {args.output}")
    print(f"\n📋 Exemplos:")
    for key in keys[:5]:
        print(f"   {key}")


if __name__ == "__main__":
    main()
