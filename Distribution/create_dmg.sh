#!/bin/bash

# Script para criar DMG installer do VibeFlow
# Uso: ./create_dmg.sh

set -e

echo "🎨 Criando DMG do VibeFlow..."

# Configurações
APP_NAME="VibeFlow"
APP_VERSION="2.1.0"
DMG_NAME="${APP_NAME}-${APP_VERSION}.dmg"
VOLUME_NAME="${APP_NAME} ${APP_VERSION}"
SOURCE_APP="../VibeFlow.app"
TEMP_DIR="temp_dmg"
OUTPUT_DIR="output"

# Verificar se o app existe
if [ ! -d "$SOURCE_APP" ]; then
    echo "❌ Erro: $SOURCE_APP não encontrado!"
    echo "💡 Compile primeiro: ./Scripts/build.sh"
    exit 1
fi

# Criar diretórios
mkdir -p "$TEMP_DIR"
mkdir -p "$OUTPUT_DIR"

# Copiar app
cp -R "$SOURCE_APP" "$TEMP_DIR/"

# Criar link para Applications
ln -s /Applications "$TEMP_DIR/Applications"

# Criar README no DMG
cat > "$TEMP_DIR/README.txt" << 'EOF'
🎙️ VibeFlow - Instalação

1. Arraste VibeFlow.app para a pasta Applications
2. Abra o app pela primeira vez
3. Siga o wizard de configuração
4. Insira sua license key quando solicitado

🆘 Suporte: suporte@vibeflow.app
🌐 Website: https://vibeflow.app
EOF

echo "📦 Criando imagem DMG..."

# Criar DMG
hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$TEMP_DIR" \
    -ov \
    -format UDZO \
    "$OUTPUT_DIR/$DMG_NAME"

# Limpar temp
rm -rf "$TEMP_DIR"

echo ""
echo "✅ DMG criado com sucesso!"
echo "📁 Local: $OUTPUT_DIR/$DMG_NAME"
echo "📊 Tamanho: $(du -h "$OUTPUT_DIR/$DMG_NAME" | cut -f1)"

# Opcional: Notarize (para distribuição sem avisos de segurança)
# echo ""
# echo "🔒 Enviando para notarização..."
# xcrun altool --notarize-app --primary-bundle-id "com.vibeflow.app" \
#     --username "seu@email.com" --password "@keychain:AC_PASSWORD" \
#     --file "$OUTPUT_DIR/$DMG_NAME"

echo ""
echo "🚀 Pronto para distribuir!"
