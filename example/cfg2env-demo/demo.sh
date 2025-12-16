#!/bin/sh
set -e

# Parse arguments
USE_GPG=false
if [ "$1" = "--gpg" ]; then
    USE_GPG=true
fi

echo "=== cfg2env + sops Demo ==="
echo

# Step 1: Setup encryption key (prefer age over GPG)
echo "Step 1: Setting up encryption key..."

if [ "$USE_GPG" = false ] && command -v age-keygen >/dev/null 2>&1; then
    # Use age (modern, simple)
    echo "Using age encryption (recommended)"
    if [ ! -f age-key.txt ]; then
        age-keygen -o age-key.txt
        echo "✓ Generated age-key.txt"
    else
        echo "✓ age-key.txt already exists"
    fi
    AGE_PUBLIC_KEY=$(grep "public key:" age-key.txt | cut -d' ' -f4)
    echo "  Public key: $AGE_PUBLIC_KEY"
    ENCRYPTION_METHOD="age"
    export SOPS_AGE_KEY_FILE="$(pwd)/age-key.txt"
else
    # Fallback to GPG
    echo "Using GPG encryption (age not found, install with: brew install age)"
    if ! gpg --list-keys "demo@cfg2env.local" >/dev/null 2>&1; then
        cat > gpg-key-config << 'GPGEOF'
%no-protection
Key-Type: RSA
Key-Length: 2048
Name-Real: cfg2env Demo
Name-Email: demo@cfg2env.local
Expire-Date: 0
%commit
GPGEOF
        gpg --batch --generate-key gpg-key-config 2>&1 | grep -q "revocation" && echo "✓ GPG key created"
    else
        echo "✓ GPG key already exists"
    fi
    GPG_FP=$(gpg --list-keys --with-colons "demo@cfg2env.local" | grep "^fpr" | head -1 | cut -d: -f10)
    echo "  Fingerprint: $GPG_FP"
    ENCRYPTION_METHOD="gpg"
fi
echo

# Step 2: Create sample config
echo "Step 2: Creating sample config..."
cat > config.yaml << 'YAMLEOF'
database:
  host: prod-db.example.com
  port: 5432
  credentials:
    username: admin
    password: super-secret-password
api:
  key: sk_live_abc123xyz789
  endpoint: https://api.example.com
  timeout: 30
YAMLEOF
echo "✓ Created config.yaml"
cat config.yaml
echo

# Step 3: Encrypt with sops
echo "Step 3: Encrypting with sops..."
if [ "$ENCRYPTION_METHOD" = "age" ]; then
    sops --encrypt --age "$AGE_PUBLIC_KEY" config.yaml > config.enc.yaml
else
    sops --encrypt --pgp "$GPG_FP" config.yaml > config.enc.yaml
fi
echo "✓ Created config.enc.yaml ($(wc -c < config.enc.yaml) bytes)"
echo "  First few lines:"
head -5 config.enc.yaml
echo

# Step 4: Decrypt and convert to .env
echo "Step 4: Decrypting and converting to .env..."
echo "  Command: sops -d config.enc.yaml | cfg2env > .env"
sops -d config.enc.yaml | cfg2env > .env
echo "✓ Generated .env file"
echo

# Step 5: Show results
echo "Step 5: Results"
echo "  .env contents:"
cat .env | grep -v "^#"
echo

# Step 6: Verify it works
echo "Step 6: Verification"
. ./.env
echo "  DATABASE_HOST=$DATABASE_HOST"
echo "  API_KEY=$API_KEY"
echo

echo "=== Demo Complete ==="
echo "Files created:"
ls -lh config.yaml config.enc.yaml .env
