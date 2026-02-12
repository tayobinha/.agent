#!/bin/bash
# RMM SaaS - Secrets Generator
# Generates cryptographically secure secrets for production use

set -e

echo "🔐 RMM SaaS - Secrets Generator"
echo "================================"

# Create secrets directory with restricted permissions
mkdir -p .secrets
chmod 700 .secrets

# Generate JWT Secret (256-bit)
echo "Generating JWT Secret (256-bit)..."
openssl rand -hex 32 > .secrets/jwt_secret

# Generate Client Token (192-bit)
echo "Generating Client Token (192-bit)..."
openssl rand -base64 24 > .secrets/client_token

# Generate Database Password (256-bit)
echo "Generating Database Password..."
openssl rand -base64 32 > .secrets/db_password

# Set restrictive permissions
chmod 600 .secrets/*

echo ""
echo "✅ Secrets generated successfully!"
echo ""
echo "📁 Location: .secrets/"
echo "   - jwt_secret"
echo "   - client_token"
echo "   - db_password"
echo ""
echo "⚠️  IMPORTANT:"
echo "   1. Never commit .secrets/ to Git"
echo "   2. Backup secrets securely (encrypted)"
echo "   3. Rotate secrets every 90 days"
echo ""
echo "🔧 Next steps:"
echo "   1. Update .env to use: USE_SECRETS_FILE"
echo "   2. Configure backend to read from .secrets/"
echo "   3. Test with: go run cmd/server/main.go"
echo ""
