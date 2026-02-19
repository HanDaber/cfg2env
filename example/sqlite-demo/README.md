# cfg2env + SQLite Demo

This directory demonstrates the complete SQLite integration capabilities of `cfg2env`.

## Quick Start

```bash
./demo.sh
```

## Overview

SQLite is a powerful embedded database that can store configuration in a structured, queryable format. This demo shows:

- **Default key-value storage** - Simple config table
- **Custom queries** - Extract from any table structure
- **Multiple tables** - Join different config sources
- **Real-world patterns** - App settings, feature flags, environments

## Use Cases

### 1. Default Key-Value Storage

The simplest pattern - a single `config` table with `key` and `value` columns:

```bash
cat config.db | cfg2env > .env
```

Default query: `SELECT key, value FROM config`

### 2. Custom Table Schema

Extract from any table structure with custom column names:

```bash
cat settings.db | cfg2env --format sqlite --query "SELECT name as key, val as value FROM settings" > .env
```

### 3. Feature Flags

Enable/disable features using a dedicated flags table:

```bash
cat features.db | cfg2env --format sqlite --query "SELECT name as key, CASE WHEN enabled THEN 'true' ELSE 'false' END as value FROM feature_flags WHERE enabled = 1" > .env
```

### 4. Environment-Specific Configs

Extract configuration for a specific environment:

```bash
cat multi-env.db | cfg2env --format sqlite --query "SELECT key, value FROM config WHERE environment = 'production'" > .env.production
```

### 5. Joined Multi-Table Configs

Combine data from multiple tables:

```bash
cat complex.db | cfg2env --format sqlite --query "
  SELECT 
    s.setting_name as key,
    s.setting_value as value
  FROM settings s
  JOIN applications a ON s.app_id = a.id
  WHERE a.name = 'web-app' AND s.active = 1
" > .env
```

### 6. Configuration with Metadata

Extract configs with type casting or filtering:

```bash
cat typed-config.db | cfg2env --format sqlite --query "
  SELECT 
    key,
    CASE 
      WHEN type = 'int' THEN CAST(value AS TEXT)
      WHEN type = 'bool' THEN CASE value WHEN '1' THEN 'true' ELSE 'false' END
      ELSE value
    END as value
  FROM config_metadata
  WHERE active = 1
" > .env
```

## Database Schemas

### Schema 1: Simple Key-Value (default)
```sql
CREATE TABLE config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
```

### Schema 2: Settings with Metadata
```sql
CREATE TABLE settings (
  id INTEGER PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  val TEXT NOT NULL,
  description TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### Schema 3: Feature Flags
```sql
CREATE TABLE feature_flags (
  id INTEGER PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  enabled BOOLEAN DEFAULT 0,
  rollout_percentage INTEGER DEFAULT 0,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### Schema 4: Multi-Environment
```sql
CREATE TABLE config (
  id INTEGER PRIMARY KEY,
  environment TEXT NOT NULL,
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  UNIQUE(environment, key)
);
```

### Schema 5: Multi-Table with Relations
```sql
CREATE TABLE applications (
  id INTEGER PRIMARY KEY,
  name TEXT UNIQUE NOT NULL
);

CREATE TABLE settings (
  id INTEGER PRIMARY KEY,
  app_id INTEGER NOT NULL,
  setting_name TEXT NOT NULL,
  setting_value TEXT NOT NULL,
  active BOOLEAN DEFAULT 1,
  FOREIGN KEY (app_id) REFERENCES applications(id)
);
```

## Demo Walkthrough

The `demo.sh` script creates and demonstrates all these patterns:

1. **Simple Config** - Basic key-value pairs
2. **Custom Schema** - Settings table with different column names
3. **Feature Flags** - Boolean flags for feature toggles
4. **Multi-Environment** - Different configs per environment (dev/staging/prod)
5. **Complex Query** - Joins, filtering, and transformations

## Files Generated

- `simple.db` - Basic key-value config table
- `settings.db` - Custom schema with metadata
- `features.db` - Feature flags database
- `multi-env.db` - Multi-environment configurations
- `complex.db` - Multi-table with relationships
- Various `.env` files for each example

## Advantages of SQLite for Config

✅ **Structured Data** - Relational model for complex configs  
✅ **Queryable** - Use SQL to filter, join, and transform  
✅ **Type Safety** - Column types enforce data integrity  
✅ **Transactional** - Atomic updates to configuration  
✅ **Portable** - Single file, works everywhere  
✅ **No Server** - Embedded database, zero dependencies  
✅ **Version Control** - Binary file that can be tracked (or use schema + seeds)  

## Real-World Scenarios

### CI/CD Pipeline
```bash
# Extract production config from database
cat config/prod.db | cfg2env --format sqlite > .env.production

# Deploy with environment variables
docker run --env-file .env.production myapp:latest
```

### Microservices Configuration
```bash
# Extract service-specific config
for service in api worker scheduler; do
  cat services.db | cfg2env --format sqlite \
    --query "SELECT key, value FROM config WHERE service = '${service}'" \
    > .env.${service}
done
```

### Dynamic Feature Flags
```bash
# Export only enabled features
cat features.db | cfg2env --format sqlite \
  --query "SELECT name as key, 'true' as value FROM feature_flags WHERE enabled = 1" \
  > .env.features
```

### Configuration Inheritance
```bash
# Combine base + environment-specific configs
cat config.db | cfg2env --format sqlite \
  --query "SELECT key, value FROM config WHERE environment IN ('base', 'production') ORDER BY environment" \
  > .env.production
```

## Tips

- **Column Order Matters**: First column is key, second is value
- **Aliases Required**: Use `AS key` and `AS value` if columns have different names
- **Quote Handling**: Multi-line queries need proper shell quoting
- **Testing Queries**: Use `sqlite3 database.db "YOUR_QUERY"` to test before piping to cfg2env
- **Schema First**: Design your schema with cfg2env extraction in mind

## Testing Custom Queries

Before using a query with cfg2env, test it directly:

```bash
# Test query output
sqlite3 complex.db "SELECT key, value FROM config WHERE environment = 'prod'"

# Verify it works with cfg2env
sqlite3 complex.db "SELECT key, value FROM config WHERE environment = 'prod'" | \
  sqlite3 :memory: '.import /dev/stdin temp' '.mode list' '.separator |' 'SELECT * FROM temp'
```

## Limitations

- SQLite query must return exactly 2 columns (key, value)
- Both columns must be TEXT or convertible to TEXT
- First row must not be headers (pure data rows only)
- Database must be readable and valid SQLite3 format

## Further Reading

- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [SQL Query Syntax](https://www.sqlite.org/lang_select.html)
- [SQLite Data Types](https://www.sqlite.org/datatype3.html)

---

MIT License • Part of cfg2env examples