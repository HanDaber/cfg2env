# cfg2env + sops Demo

This directory demonstrates the complete workflow of using `sops` for encryption and `cfg2env` for conversion.

## Quick Start

```bash
./demo.sh
```

## Workflow Summary

### 1. Setup Encryption

**Option A: age (Recommended)**
```bash
age-keygen -o age-key.txt
# Public key: age1gvcg05jj9asee7cdv4r438f0453v4tu6hwf6upha4v27exkd3f9qj9amlq
```
- Modern, simple encryption tool
- No passphrase needed
- Short, easy-to-use keys

**Option B: GPG (Fallback)**
```bash
gpg --batch --generate-key gpg-key-config
```
- Traditional encryption method
- More complex setup
- Widely supported

### 2. Create Config
- Write sensitive configuration in YAML format
- Contains database credentials, API keys, etc.

### 3. Encrypt with sops

**With age:**
```bash
sops --encrypt --age <public-key> config.yaml > config.enc.yaml
```

**With GPG:**
```bash
sops --encrypt --pgp <fingerprint> config.yaml > config.enc.yaml
```
- Encrypts all values with AES256_GCM
- Safe to commit to version control

### 4. Decrypt and Convert

**With age:**
```bash
SOPS_AGE_KEY_FILE=age-key.txt sops -d config.enc.yaml | cfg2env > .env
```

**With GPG:**
```bash
sops -d config.enc.yaml | cfg2env > .env
```
- Decrypts in memory (never writes plain text to disk)
- Pipes directly to cfg2env
- Outputs flattened .env format

### 5. Use .env File
```bash
source .env
echo $DATABASE_HOST
```

## Files

- `demo.sh` - Complete automated demo script (supports both age and GPG)
- `age-key.txt` - age encryption key (if using age)
- `config.yaml` - Original plain configuration
- `config.enc.yaml` - Encrypted with sops
- `.env` - Final output from cfg2env

## Why age over GPG?

- **Simpler**: One command to generate keys, no complex setup
- **Modern**: Uses modern cryptography (X25519, ChaCha20-Poly1305)
- **Faster**: Designed for file encryption specifically
- **No passphrase**: Keys stored securely without interactive prompts
- **Shorter keys**: Easy to copy/paste (e.g., `age1gvcg05jj9asee7cdv4r438f0453v4tu6hwf6upha4v27exkd3f9qj9amlq`)

Install age: `brew install age` (macOS) or `apt install age` (Linux)

## Use Cases

**Development**: Keep encrypted configs in git, decrypt locally
```bash
# With age
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d secrets.yaml | cfg2env > .env.local

# With GPG (auto-detects key)
sops -d secrets.yaml | cfg2env > .env.local
```

**CI/CD**: Decrypt and convert in pipeline
```bash
# Set age key in CI environment
export SOPS_AGE_KEY_FILE=/secrets/age-key.txt
sops -d config/prod.enc.yaml | cfg2env > .env.production
```

**Multiple Environments**:
```bash
export SOPS_AGE_KEY_FILE=age-key.txt
for env in dev staging prod; do
  sops -d "config/${env}.enc.yaml" | cfg2env > ".env.${env}"
done
```
