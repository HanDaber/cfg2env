<div align="center">

# cfg2env

> A plugin-based tool for converting any config format to `.env`

[![Go](https://img.shields.io/badge/Go-1.21+-00ADD8?style=flat&logo=go)](https://go.dev)
[![MIT License](https://img.shields.io/badge/license-MIT-blue?style=flat)](LICENSE)

---

</div>

## 💡 Use Cases

```bash
# Decrypt sops gpg-encrypted configs
sops -d secrets.yaml | cfg2env > .env
# or age-encrypted
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops -d secrets.yaml | cfg2env > .env

# Extract Kubernetes ConfigMap data
kubectl get configmap my-config -o json | jq .data | cfg2env --format json > .env

# Convert Terraform outputs
terraform output -json | cfg2env --format json > .env

# Process remote configs
curl -s https://api.example.com/config | cfg2env --format json > .env
```

## 🔌 Supported Formats

Built-in plugins handle common configuration formats:

- **YAML** - Complex nested structures
- **JSON** - Modern API configs
- **SQLite** - Database-driven settings
- _Your format here!_ - [Add a plugin](#-adding-plugins)

## ✨ Core Features

- Plugin-based architecture for unlimited format support
- Smart key flattening for nested structures
- Preserves array indices
- Type-safe conversions
- Clean `.env` output
- Customizable underscore handling with `--dunder` parameter
- Flexible filtering with `--include` and `--exclude` glob patterns

## 🚀 Installation

### Quick Install (Recommended)

```bash
# Install latest version
curl -fsSL https://raw.githubusercontent.com/HanDaber/cfg2env/main/install.sh | sh

# Install specific version
curl -fsSL https://raw.githubusercontent.com/HanDaber/cfg2env/main/install.sh | VERSION=v0.1.0 sh

# Custom install directory
curl -fsSL https://raw.githubusercontent.com/HanDaber/cfg2env/main/install.sh | INSTALL_DIR=~/bin sh
```

### Alternative Methods

```bash
# Via Go
go install github.com/handaber/cfg2env@latest

# From source
git clone https://github.com/HanDaber/cfg2env.git
cd cfg2env
./install.sh --local
```

## 🚀 Quick Start

```bash
# Use with any supported format
cat config.yaml | cfg2env > .env
cat config.json | cfg2env --format json > .env
cat config.db | cfg2env --format sqlite > .env

# Control underscore handling
cat config.yaml | cfg2env --dunder 1 > .env  # Remove 1 underscore from consecutive sequences
cat config.yaml | cfg2env --dunder 3 > .env  # Remove 3 underscores from consecutive sequences

# Filter output keys
cat config.yaml | cfg2env --include "DATABASE_*,API_*" > .env      # Only DATABASE_* and API_* keys
cat config.yaml | cfg2env --exclude "*_PASSWORD,*_SECRET" > .env   # Exclude sensitive keys
cat config.yaml | cfg2env --include "DATABASE_*" --exclude "*_PASSWORD" > .env  # Combine both
```

## 📋 Examples

<details>
<summary><b>YAML Plugin</b></summary>

```yaml
database:
  host: localhost
  port: 5432
  credentials:
    username: admin
    password: secret
api:
  features:
    - logging
    - metrics
```
</details>

<details>
<summary><b>JSON Plugin</b></summary>

```json
{
  "database": {
    "host": "localhost",
    "port": 5432,
    "credentials": {
      "username": "admin",
      "password": "secret"
    }
  },
  "api": {
    "features": ["logging", "metrics"]
  }
}
```
</details>

<details>
<summary><b>SQLite Plugin</b></summary>

```sql
CREATE TABLE config (
  key TEXT PRIMARY KEY,
  value TEXT
);

INSERT INTO config (key, value) VALUES
  ('database_host', 'localhost'),
  ('database_port', '5432');

-- Custom queries supported:
-- cfg2env --format sqlite --query "SELECT name as key, value FROM settings"
```
</details>

<details>
<summary><b>Output (.env)</b></summary>

```env
API_FEATURES_0=logging
API_FEATURES_1=metrics
DATABASE_CREDENTIALS_PASSWORD=secret
DATABASE_CREDENTIALS_USERNAME=admin
DATABASE_HOST=localhost
DATABASE_PORT=5432
```
</details>

<details>
<summary><b>Dunder Examples</b></summary>

With `--dunder 1`:
```env
# Input: example_key
EXAMPLEKEY=value

# Input: example__key
EXAMPLE_KEY=value

# Input: example____key
EXAMPLE___KEY=value
```

With `--dunder 3`:
```env
# Input: example_key
EXAMPLEKEY=value

# Input: example__key
EXAMPLEKEY=value

# Input: example____key
EXAMPLE_KEY=value
```
</details>

<details>
<summary><b>Filtering Examples</b></summary>

```bash
# Include only DATABASE keys
cat config.yaml | cfg2env --include "DATABASE_*"
# Output: DATABASE_HOST, DATABASE_PORT, DATABASE_PASSWORD

# Exclude sensitive keys
cat config.yaml | cfg2env --exclude "*_PASSWORD,*_SECRET,*_TOKEN"
# Output: All keys except those ending in _PASSWORD, _SECRET, or _TOKEN

# Combine include and exclude (include first, then exclude)
cat config.yaml | cfg2env --include "DATABASE_*" --exclude "*_PASSWORD"
# Output: DATABASE_HOST, DATABASE_PORT (excludes DATABASE_PASSWORD)

# Patterns are case-insensitive and normalized
cat config.yaml | cfg2env --include "database_*"  # Same as "DATABASE_*"

# No matches produces empty output with comment
cat config.yaml | cfg2env --include "NONEXISTENT_*"
# Output: # No keys matched the specified filters
```
</details>

## 🛠️ Development

```bash
make build  # Build the core and plugins
make test   # Run the test suite
```

## 🔌 Adding Plugins

The plugin system makes it easy to add support for new formats:

```go
package myplugin

type Plugin struct {
    plugin.BasePlugin
}

func (p *Plugin) Parse(r io.Reader) (map[string]string, error) {
    // 1. Read your format
    // 2. Convert to key-value pairs
    // 3. Return the mapping
    return map[string]string{}, nil
}
```

<div align="center">

---

MIT License • Built with 🍑 using Go

</div> 