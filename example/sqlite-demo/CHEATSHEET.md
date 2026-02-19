# cfg2env SQLite Quick Reference

## Basic Usage

```bash
# Default schema (key, value columns)
cat config.db | cfg2env --format sqlite > .env

# Custom query
cat config.db | cfg2env --format sqlite --query "SELECT name as key, val as value FROM settings" > .env
```

## Common Query Patterns

### 1. Simple Key-Value
```sql
SELECT key, value FROM config
```

### 2. Custom Column Names
```sql
SELECT name as key, val as value FROM settings
```

### 3. Filter by Environment
```sql
SELECT key, value FROM config WHERE environment = 'production'
```

### 4. Boolean Conversion
```sql
SELECT 
  name as key, 
  CASE WHEN enabled THEN 'true' ELSE 'false' END as value 
FROM feature_flags
```

### 5. Join Multiple Tables
```sql
SELECT 
  s.setting_name as key, 
  s.setting_value as value
FROM settings s
JOIN applications a ON s.app_id = a.id
WHERE a.name = 'web-app' AND a.active = 1
```

### 6. Filter Active Records
```sql
SELECT key, value FROM config WHERE active = 1
```

### 7. Namespace Prefix
```sql
SELECT namespace || '_' || key as key, value FROM config
```

### 8. Shared + Service-Specific
```sql
SELECT key, value FROM config 
WHERE service IS NULL OR service = 'api'
ORDER BY priority DESC
```

### 9. Type Casting
```sql
SELECT 
  key,
  CASE 
    WHEN type = 'bool' THEN CASE value WHEN '1' THEN 'true' ELSE 'false' END
    WHEN type = 'int' THEN CAST(value AS TEXT)
    ELSE value
  END as value
FROM config
```

### 10. Versioned Secrets
```sql
SELECT secret_name as key, secret_value as value 
FROM secrets 
WHERE active = 1
ORDER BY version DESC
```

## Schema Examples

### Default (Simple)
```sql
CREATE TABLE config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
```

### With Metadata
```sql
CREATE TABLE settings (
  id INTEGER PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  val TEXT NOT NULL,
  description TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### Multi-Environment
```sql
CREATE TABLE config (
  id INTEGER PRIMARY KEY,
  environment TEXT NOT NULL,
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  UNIQUE(environment, key)
);
```

### Feature Flags
```sql
CREATE TABLE feature_flags (
  id INTEGER PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  enabled BOOLEAN DEFAULT 0,
  rollout_percentage INTEGER DEFAULT 0
);
```

### Multi-Tenant
```sql
CREATE TABLE tenant_configs (
  id INTEGER PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  config_key TEXT NOT NULL,
  config_value TEXT NOT NULL,
  UNIQUE(tenant_id, config_key)
);
```

## Real-World Commands

### Docker Deployment
```bash
cat prod.db | cfg2env --format sqlite > .env
docker run --env-file .env myapp:latest
```

### Kubernetes Secrets
```bash
cat secrets.db | cfg2env --format sqlite \
  --query "SELECT key, value FROM secrets WHERE active = 1" | \
  kubectl create secret generic app-secrets --from-env-file=/dev/stdin
```

### Per-Service Extraction
```bash
for service in api worker scheduler; do
  cat services.db | cfg2env --format sqlite \
    --query "SELECT key, value FROM config WHERE service = '${service}'" \
    > ".env.${service}"
done
```

### Multi-Environment CI/CD
```bash
for env in dev staging prod; do
  cat config.db | cfg2env --format sqlite \
    --query "SELECT key, value FROM config WHERE environment = '${env}'" \
    > ".env.${env}"
done
```

### Feature Flags Only Enabled
```bash
cat features.db | cfg2env --format sqlite \
  --query "SELECT name as key, 'true' as value FROM feature_flags WHERE enabled = 1" \
  > features.env
```

### Tenant-Specific Config
```bash
TENANT_ID="acme-corp"
cat tenants.db | cfg2env --format sqlite \
  --query "SELECT config_key as key, config_value as value FROM tenant_configs WHERE tenant_id = '${TENANT_ID}'" \
  > "tenant.${TENANT_ID}.env"
```

## Testing Queries

Before using with cfg2env, test your SQL query:

```bash
# Test query syntax
sqlite3 config.db "YOUR_QUERY_HERE"

# Verify output format (should be 2 columns)
sqlite3 config.db "SELECT key, value FROM config" | head

# Check for issues
sqlite3 config.db ".schema"
sqlite3 config.db ".tables"
```

## Tips & Tricks

✅ **DO:**
- Always return exactly 2 columns (key, value)
- Use `AS key` and `AS value` aliases when needed
- Test queries with sqlite3 first
- Use `WHERE active = 1` to filter inactive records
- Add `ORDER BY` for consistent output

❌ **DON'T:**
- Return more or fewer than 2 columns
- Forget to convert boolean columns to strings
- Use NULL values (will cause errors)
- Return duplicate keys (last value wins)

## Troubleshooting

**Error: "no such table"**
```bash
sqlite3 config.db ".tables"  # List all tables
```

**Error: "no such column"**
```bash
sqlite3 config.db ".schema config"  # Show table schema
```

**Empty output**
```bash
sqlite3 config.db "SELECT COUNT(*) FROM config"  # Check row count
sqlite3 config.db "YOUR_QUERY" | wc -l  # Test query
```

**Unexpected results**
```bash
# Verify query output directly
sqlite3 config.db "YOUR_QUERY"
```

## Performance Tips

- Add indexes on frequently queried columns:
  ```sql
  CREATE INDEX idx_environment ON config(environment);
  CREATE INDEX idx_active ON config(active);
  ```

- Use EXPLAIN QUERY PLAN to optimize:
  ```bash
  sqlite3 config.db "EXPLAIN QUERY PLAN YOUR_QUERY"
  ```

## Security Considerations

🔒 **Best Practices:**
- Never commit unencrypted databases with secrets
- Use file permissions: `chmod 600 secrets.db`
- Consider encrypting sensitive databases
- Rotate secrets regularly
- Use version control for schema only, not data
- Audit access to configuration databases

## Quick Start Examples

```bash
# 1. Create a simple config database
sqlite3 config.db << EOF
CREATE TABLE config (key TEXT PRIMARY KEY, value TEXT);
INSERT INTO config VALUES ('API_KEY', 'secret'), ('PORT', '8080');
EOF

# 2. Convert to .env
cat config.db | cfg2env --format sqlite > .env

# 3. Use it
source .env
echo $API_KEY
```

---

**More Info:** See `README.md` for detailed documentation and `demo.sh` for interactive examples.