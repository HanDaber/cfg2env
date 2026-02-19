#!/bin/sh
set -e

echo "=== cfg2env + SQLite Demo ==="
echo

# Colors for output (if terminal supports it)
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color
else
    GREEN=''
    BLUE=''
    YELLOW=''
    NC=''
fi

print_step() {
    echo "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo "${GREEN}✓ $1${NC}"
}

print_info() {
    echo "${YELLOW}→ $1${NC}"
}

# Check dependencies
check_deps() {
    if ! command -v sqlite3 >/dev/null 2>&1; then
        echo "Error: sqlite3 is required but not installed."
        echo "Install with: brew install sqlite (macOS) or apt install sqlite3 (Linux)"
        exit 1
    fi

    if ! command -v cfg2env >/dev/null 2>&1; then
        echo "Error: cfg2env is not in PATH."
        echo "Please build and install cfg2env first: make build && make install"
        exit 1
    fi
}

check_deps

# Cleanup from previous runs
rm -f *.db *.env 2>/dev/null || true

# Demo 1: Simple Key-Value Config
print_step "Demo 1: Simple Key-Value Config (Default Schema)"
echo

sqlite3 simple.db << 'SQL'
CREATE TABLE config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

INSERT INTO config (key, value) VALUES
  ('database_host', 'localhost'),
  ('database_port', '5432'),
  ('database_name', 'myapp'),
  ('database_user', 'admin'),
  ('database_password', 'secret123'),
  ('api_key', 'sk_live_abc123xyz789'),
  ('api_endpoint', 'https://api.example.com'),
  ('api_timeout', '30'),
  ('log_level', 'info'),
  ('max_connections', '100');
SQL

print_success "Created simple.db with config table"
print_info "Schema: key TEXT, value TEXT"
print_info "Query: (default) SELECT key, value FROM config"
echo

echo "Database contents:"
sqlite3 simple.db "SELECT key, value FROM config ORDER BY key" | head -5
echo "... (10 total rows)"
echo

print_info "Converting to .env..."
cat simple.db | cfg2env --format sqlite > simple.env
print_success "Generated simple.env"
echo

echo "Output (.env format):"
head -5 simple.env
echo "... (10 total rows)"
echo

# Demo 2: Custom Schema with Different Column Names
print_step "Demo 2: Custom Schema with Metadata"
echo

sqlite3 settings.db << 'SQL'
CREATE TABLE settings (
  id INTEGER PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  val TEXT NOT NULL,
  description TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO settings (name, val, description) VALUES
  ('app_name', 'MyApplication', 'Application display name'),
  ('app_version', '2.1.0', 'Current application version'),
  ('cache_ttl', '3600', 'Cache time-to-live in seconds'),
  ('session_timeout', '1800', 'Session timeout in seconds'),
  ('enable_debug', 'false', 'Enable debug mode'),
  ('max_upload_size', '10485760', 'Max upload size in bytes (10MB)');
SQL

print_success "Created settings.db with custom schema"
print_info "Schema: id, name, val, description, created_at"
print_info "Query: SELECT name as key, val as value FROM settings"
echo

echo "Database contents:"
sqlite3 settings.db "SELECT name, val, description FROM settings" | head -3
echo "..."
echo

print_info "Converting with custom query..."
cat settings.db | cfg2env --format sqlite --query "SELECT name as key, val as value FROM settings" > settings.env
print_success "Generated settings.env"
echo

echo "Output:"
cat settings.env
echo

# Demo 3: Feature Flags
print_step "Demo 3: Feature Flags"
echo

sqlite3 features.db << 'SQL'
CREATE TABLE feature_flags (
  id INTEGER PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  enabled BOOLEAN DEFAULT 0,
  rollout_percentage INTEGER DEFAULT 0,
  description TEXT,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO feature_flags (name, enabled, rollout_percentage, description) VALUES
  ('new_ui', 1, 100, 'New user interface'),
  ('beta_api', 1, 50, 'Beta API endpoints'),
  ('experimental_cache', 0, 0, 'Experimental caching system'),
  ('dark_mode', 1, 100, 'Dark mode theme'),
  ('analytics', 1, 100, 'Analytics tracking'),
  ('premium_features', 0, 0, 'Premium tier features'),
  ('social_login', 1, 75, 'Social media authentication');
SQL

print_success "Created features.db with feature flags"
print_info "Schema: name, enabled, rollout_percentage, description"
echo

echo "All features:"
sqlite3 features.db "SELECT name, enabled, rollout_percentage FROM feature_flags"
echo

print_info "Extracting only enabled features..."
cat features.db | cfg2env --format sqlite --query "SELECT name as key, CASE WHEN enabled THEN 'true' ELSE 'false' END as value FROM feature_flags WHERE enabled = 1" > features.env
print_success "Generated features.env (enabled features only)"
echo

echo "Output (enabled features):"
cat features.env
echo

# Demo 4: Multi-Environment Configuration
print_step "Demo 4: Multi-Environment Configuration"
echo

sqlite3 multi-env.db << 'SQL'
CREATE TABLE config (
  id INTEGER PRIMARY KEY,
  environment TEXT NOT NULL,
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  UNIQUE(environment, key)
);

INSERT INTO config (environment, key, value) VALUES
  -- Development
  ('development', 'database_host', 'localhost'),
  ('development', 'database_port', '5432'),
  ('development', 'debug_mode', 'true'),
  ('development', 'log_level', 'debug'),
  ('development', 'api_endpoint', 'http://localhost:3000'),

  -- Staging
  ('staging', 'database_host', 'staging-db.example.com'),
  ('staging', 'database_port', '5432'),
  ('staging', 'debug_mode', 'false'),
  ('staging', 'log_level', 'info'),
  ('staging', 'api_endpoint', 'https://staging-api.example.com'),

  -- Production
  ('production', 'database_host', 'prod-db.example.com'),
  ('production', 'database_port', '5432'),
  ('production', 'debug_mode', 'false'),
  ('production', 'log_level', 'warn'),
  ('production', 'api_endpoint', 'https://api.example.com');
SQL

print_success "Created multi-env.db with 3 environments"
print_info "Environments: development, staging, production"
echo

echo "All environments:"
sqlite3 multi-env.db "SELECT environment, key, value FROM config ORDER BY environment, key" | head -10
echo "... (15 total rows)"
echo

for env in development staging production; do
    print_info "Extracting ${env} configuration..."
    cat multi-env.db | cfg2env --format sqlite --query "SELECT key, value FROM config WHERE environment = '${env}'" > ".env.${env}"
    print_success "Generated .env.${env}"
done
echo

echo "Production environment (.env.production):"
cat .env.production
echo

# Demo 5: Complex Multi-Table Query
print_step "Demo 5: Complex Multi-Table with Joins"
echo

sqlite3 complex.db << 'SQL'
CREATE TABLE applications (
  id INTEGER PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  active BOOLEAN DEFAULT 1
);

CREATE TABLE app_settings (
  id INTEGER PRIMARY KEY,
  app_id INTEGER NOT NULL,
  setting_name TEXT NOT NULL,
  setting_value TEXT NOT NULL,
  active BOOLEAN DEFAULT 1,
  priority INTEGER DEFAULT 0,
  FOREIGN KEY (app_id) REFERENCES applications(id)
);

INSERT INTO applications (name, active) VALUES
  ('web-app', 1),
  ('mobile-app', 1),
  ('admin-panel', 0);

INSERT INTO app_settings (app_id, setting_name, setting_value, active, priority) VALUES
  -- Web app settings
  (1, 'server_port', '8080', 1, 10),
  (1, 'enable_cors', 'true', 1, 10),
  (1, 'max_request_size', '10485760', 1, 5),
  (1, 'rate_limit', '1000', 1, 10),
  (1, 'session_secret', 'super-secret-key', 1, 10),

  -- Mobile app settings
  (2, 'api_version', 'v2', 1, 10),
  (2, 'push_enabled', 'true', 1, 10),
  (2, 'offline_mode', 'true', 1, 5),

  -- Admin panel (inactive app)
  (3, 'admin_port', '9090', 1, 10),
  (3, 'require_2fa', 'true', 1, 10);
SQL

print_success "Created complex.db with relational structure"
print_info "Tables: applications, app_settings"
echo

echo "Database structure:"
sqlite3 complex.db << 'SQL'
SELECT
  a.name as app,
  s.setting_name,
  s.setting_value,
  s.active
FROM app_settings s
JOIN applications a ON s.app_id = a.id
ORDER BY a.name, s.setting_name;
SQL
echo

print_info "Extracting web-app settings with JOIN..."
cat complex.db | cfg2env --format sqlite --query "SELECT s.setting_name as key, s.setting_value as value FROM app_settings s JOIN applications a ON s.app_id = a.id WHERE a.name = 'web-app' AND a.active = 1 AND s.active = 1 ORDER BY s.priority DESC, s.setting_name" > complex-web.env
print_success "Generated complex-web.env"
echo

echo "Output (web-app settings only):"
cat complex-web.env
echo

print_info "Extracting mobile-app settings..."
cat complex.db | cfg2env --format sqlite --query "SELECT s.setting_name as key, s.setting_value as value FROM app_settings s JOIN applications a ON s.app_id = a.id WHERE a.name = 'mobile-app' AND a.active = 1 AND s.active = 1" > complex-mobile.env
print_success "Generated complex-mobile.env"
echo

echo "Output (mobile-app settings):"
cat complex-mobile.env
echo

# Demo 6: Type Casting and Transformations
print_step "Demo 6: Type Casting and Transformations"
echo

sqlite3 typed-config.db << 'SQL'
CREATE TABLE config_metadata (
  id INTEGER PRIMARY KEY,
  key TEXT UNIQUE NOT NULL,
  value TEXT NOT NULL,
  type TEXT NOT NULL,
  active BOOLEAN DEFAULT 1
);

INSERT INTO config_metadata (key, value, type, active) VALUES
  ('max_connections', '100', 'int', 1),
  ('timeout_seconds', '30', 'int', 1),
  ('enable_ssl', '1', 'bool', 1),
  ('enable_compression', '0', 'bool', 1),
  ('server_name', 'production-server', 'string', 1),
  ('api_key', 'sk_live_xyz', 'string', 1),
  ('retry_limit', '5', 'int', 1),
  ('deprecated_setting', 'old_value', 'string', 0);
SQL

print_success "Created typed-config.db with type metadata"
print_info "Schema includes type information for each config"
echo

echo "Database contents:"
sqlite3 typed-config.db "SELECT key, value, type, active FROM config_metadata"
echo

print_info "Converting with type transformations..."
cat typed-config.db | cfg2env --format sqlite --query "SELECT key, CASE WHEN type = 'bool' THEN CASE value WHEN '1' THEN 'true' ELSE 'false' END ELSE value END as value FROM config_metadata WHERE active = 1" > typed.env
print_success "Generated typed.env (active configs with boolean conversion)"
echo

echo "Output (booleans converted to true/false):"
cat typed.env
echo

# Summary
print_step "Demo Complete! Summary"
echo

echo "Generated files:"
ls -lh *.db *.env | awk '{printf "  %-30s %8s\n", $9, $5}'
echo

print_success "All SQLite demos completed successfully!"
echo

echo "Quick reference:"
echo "  1. Simple config:      cat simple.db | cfg2env > .env"
echo "  2. Custom query:       cat settings.db | cfg2env --format sqlite --query \"SELECT name as key, val as value FROM settings\" > .env"
echo "  3. Feature flags:      cat features.db | cfg2env --format sqlite --query \"SELECT name as key, 'true' as value FROM feature_flags WHERE enabled = 1\" > .env"
echo "  4. Environment filter: cat multi-env.db | cfg2env --format sqlite --query \"SELECT key, value FROM config WHERE environment = 'production'\" > .env"
echo "  5. Table joins:        cat complex.db | cfg2env --format sqlite --query \"SELECT s.setting_name as key, s.setting_value as value FROM app_settings s JOIN applications a ON s.app_id = a.id WHERE a.name = 'web-app'\" > .env"
echo

echo "Next steps:"
echo "  - Examine the generated .db files with: sqlite3 <file.db> .dump"
echo "  - Test custom queries with: sqlite3 <file.db> \"YOUR QUERY\""
echo "  - Source the .env files: source .env.production"
echo
