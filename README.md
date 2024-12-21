<div align="center">

# cfg2env

> A plugin-based tool for converting any config format to `.env`

[![Go](https://img.shields.io/badge/Go-1.21+-00ADD8?style=flat&logo=go)](https://go.dev)
[![MIT License](https://img.shields.io/badge/license-MIT-blue?style=flat)](LICENSE)

---

</div>

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

## 🚀 Quick Start

```bash
# Install
go install github.com/handaber/cfg2env@latest

# Use with any supported format
cat config.yaml | cfg2env > .env
cat config.json | cfg2env --format json > .env
cat config.db | cfg2env --format sqlite > .env
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