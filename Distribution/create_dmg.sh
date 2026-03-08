#!/bin/bash

# Script para criar DMG installer do VoxAiGo
# Uso: ./create_dmg.sh

set -e

echo "🎨 Criando DMG do VoxAiGo..."

# Configurações
APP_NAME="VoxAiGo"
APP_VERSION="3.1.0"
TIMESTAMP=$(date +"%Y%m%d_%H%M")
DMG_NAME="${APP_NAME}-${APP_VERSION}-${TIMESTAMP}.dmg"
VOLUME_NAME="${APP_NAME} ${APP_VERSION}"
SOURCE_APP="../VoxAiGo.app"
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
🎙️ VoxAiGo - Instalação

1. Arraste VoxAiGo.app para a pasta Applications
2. Abra o app pela primeira vez
3. Siga o wizard de configuração
4. Faça login com sua conta

🆘 Suporte: suporte@voxaigo.app
🌐 Website: https://voxaigo.app
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
# xcrun altool --notarize-app --primary-bundle-id "com.voxaigo.app" \
#     --username "seu@email.com" --password "@keychain:AC_PASSWORD" \
#     --file "$OUTPUT_DIR/$DMG_NAME"

echo ""
echo "🚀 Pronto para distribuir!"
