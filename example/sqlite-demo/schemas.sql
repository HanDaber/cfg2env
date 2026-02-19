-- Schema Examples for cfg2env SQLite Plugin
-- This file contains various schema patterns you can use with cfg2env

-- ============================================================================
-- 1. SIMPLE KEY-VALUE (DEFAULT)
-- ============================================================================
-- The simplest pattern - works with default cfg2env settings
-- Usage: cat config.db | cfg2env > .env

CREATE TABLE config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

INSERT INTO config (key, value) VALUES
  ('database_host', 'localhost'),
  ('database_port', '5432'),
  ('api_key', 'secret-key');

-- ============================================================================
-- 2. SETTINGS WITH METADATA
-- ============================================================================
-- Add descriptions and timestamps for better config management
-- Usage: cat settings.db | cfg2env --format sqlite --query "SELECT name as key, val as value FROM settings" > .env

CREATE TABLE settings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE NOT NULL,
  val TEXT NOT NULL,
  description TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO settings (name, val, description) VALUES
  ('app_name', 'MyApp', 'Application name'),
  ('version', '1.0.0', 'Current version'),
  ('timeout', '30', 'Request timeout in seconds');

-- ============================================================================
-- 3. FEATURE FLAGS
-- ============================================================================
-- Boolean flags with rollout control
-- Usage: cat features.db | cfg2env --format sqlite --query "SELECT name as key, CASE WHEN enabled THEN 'true' ELSE 'false' END as value FROM feature_flags WHERE enabled = 1" > .env

CREATE TABLE feature_flags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE NOT NULL,
  enabled BOOLEAN DEFAULT 0,
  rollout_percentage INTEGER DEFAULT 0 CHECK(rollout_percentage BETWEEN 0 AND 100),
  description TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO feature_flags (name, enabled, rollout_percentage, description) VALUES
  ('new_ui', 1, 100, 'New user interface'),
  ('beta_feature', 1, 50, 'Beta feature at 50% rollout'),
  ('experimental', 0, 0, 'Experimental feature (disabled)');

-- ============================================================================
-- 4. MULTI-ENVIRONMENT
-- ============================================================================
-- Store configs for multiple environments in one table
-- Usage: cat config.db | cfg2env --format sqlite --query "SELECT key, value FROM config WHERE environment = 'production'" > .env.production

CREATE TABLE config (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  environment TEXT NOT NULL,
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(environment, key)
);

CREATE INDEX idx_environment ON config(environment);

INSERT INTO config (environment, key, value) VALUES
  ('development', 'database_host', 'localhost'),
  ('development', 'debug_mode', 'true'),
  ('staging', 'database_host', 'staging-db.example.com'),
  ('staging', 'debug_mode', 'false'),
  ('production', 'database_host', 'prod-db.example.com'),
  ('production', 'debug_mode', 'false');

-- ============================================================================
-- 5. TYPED CONFIGURATION
-- ============================================================================
-- Store type information for validation and transformation
-- Usage: cat typed.db | cfg2env --format sqlite --query "SELECT key, CASE WHEN type = 'bool' THEN CASE value WHEN '1' THEN 'true' ELSE 'false' END ELSE value END as value FROM config WHERE active = 1" > .env

CREATE TABLE config (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  key TEXT UNIQUE NOT NULL,
  value TEXT NOT NULL,
  type TEXT NOT NULL CHECK(type IN ('string', 'int', 'float', 'bool', 'json')),
  active BOOLEAN DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO config (key, value, type, active) VALUES
  ('max_connections', '100', 'int', 1),
  ('enable_ssl', '1', 'bool', 1),
  ('server_name', 'prod-server', 'string', 1),
  ('timeout', '30.5', 'float', 1),
  ('deprecated_key', 'old_value', 'string', 0);

-- ============================================================================
-- 6. MULTI-TABLE WITH RELATIONSHIPS
-- ============================================================================
-- Complex schema with foreign keys and joins
-- Usage: cat app.db | cfg2env --format sqlite --query "SELECT s.key as key, s.value as value FROM settings s JOIN applications a ON s.app_id = a.id WHERE a.name = 'web-app' AND a.active = 1" > .env

CREATE TABLE applications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE NOT NULL,
  active BOOLEAN DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE settings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  app_id INTEGER NOT NULL,
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  active BOOLEAN DEFAULT 1,
  priority INTEGER DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(app_id, key),
  FOREIGN KEY (app_id) REFERENCES applications(id) ON DELETE CASCADE
);

CREATE INDEX idx_app_settings ON settings(app_id, active);

INSERT INTO applications (name, active) VALUES
  ('web-app', 1),
  ('mobile-app', 1),
  ('admin-panel', 0);

INSERT INTO settings (app_id, key, value, active, priority) VALUES
  (1, 'server_port', '8080', 1, 10),
  (1, 'enable_cors', 'true', 1, 10),
  (1, 'max_upload_size', '10485760', 1, 5),
  (2, 'api_version', 'v2', 1, 10),
  (2, 'push_enabled', 'true', 1, 10);

-- ============================================================================
-- 7. HIERARCHICAL/NAMESPACED CONFIGURATION
-- ============================================================================
-- Use prefixes or namespaces for organizing related configs
-- Usage: cat namespaced.db | cfg2env --format sqlite --query "SELECT namespace || '_' || key as key, value FROM config WHERE namespace = 'database'" > .env

CREATE TABLE config (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  namespace TEXT NOT NULL,
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(namespace, key)
);

CREATE INDEX idx_namespace ON config(namespace);

INSERT INTO config (namespace, key, value) VALUES
  ('database', 'host', 'localhost'),
  ('database', 'port', '5432'),
  ('database', 'name', 'mydb'),
  ('redis', 'host', 'localhost'),
  ('redis', 'port', '6379'),
  ('api', 'endpoint', 'https://api.example.com'),
  ('api', 'timeout', '30');

-- ============================================================================
-- 8. SECRETS WITH AUDIT TRAIL
-- ============================================================================
-- Track who changed what and when
-- Usage: cat secrets.db | cfg2env --format sqlite --query "SELECT key, value FROM secrets WHERE active = 1 ORDER BY updated_at DESC" > .env

CREATE TABLE secrets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  key TEXT UNIQUE NOT NULL,
  value TEXT NOT NULL,
  active BOOLEAN DEFAULT 1,
  created_by TEXT,
  updated_by TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE secrets_audit (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  secret_id INTEGER NOT NULL,
  old_value TEXT,
  new_value TEXT,
  changed_by TEXT,
  changed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (secret_id) REFERENCES secrets(id)
);

INSERT INTO secrets (key, value, created_by) VALUES
  ('api_key', 'sk_live_abc123', 'admin'),
  ('db_password', 'secret123', 'admin'),
  ('jwt_secret', 'super-secret', 'admin');

-- ============================================================================
-- 9. CONFIGURATION WITH VALIDATION
-- ============================================================================
-- Add constraints and validation rules
-- Usage: cat validated.db | cfg2env --format sqlite --query "SELECT key, value FROM config WHERE value NOT NULL AND length(value) > 0" > .env

CREATE TABLE config (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  key TEXT UNIQUE NOT NULL CHECK(length(key) > 0),
  value TEXT NOT NULL CHECK(length(value) > 0),
  min_value INTEGER,
  max_value INTEGER,
  pattern TEXT,
  required BOOLEAN DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO config (key, value, min_value, max_value, required) VALUES
  ('port', '8080', 1024, 65535, 1),
  ('workers', '4', 1, 32, 1),
  ('timeout', '30', 1, 300, 1),
  ('api_key', 'sk_test_key', NULL, NULL, 1);

-- ============================================================================
-- 10. SERVICE-SPECIFIC CONFIGURATION
-- ============================================================================
-- Microservices architecture with shared and service-specific configs
-- Usage: cat services.db | cfg2env --format sqlite --query "SELECT key, value FROM config WHERE service IS NULL OR service = 'api'" > .env.api

CREATE TABLE config (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  service TEXT,  -- NULL means shared across all services
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(service, key)
);

CREATE INDEX idx_service ON config(service);

INSERT INTO config (service, key, value) VALUES
  (NULL, 'log_level', 'info'),           -- Shared
  (NULL, 'environment', 'production'),   -- Shared
  ('api', 'port', '8080'),              -- API-specific
  ('api', 'rate_limit', '1000'),        -- API-specific
  ('worker', 'concurrency', '10'),      -- Worker-specific
  ('worker', 'queue_name', 'default');  -- Worker-specific

-- ============================================================================
-- QUERY EXAMPLES
-- ============================================================================

-- Get all configs for a specific environment
-- SELECT key, value FROM config WHERE environment = 'production';

-- Get only enabled feature flags
-- SELECT name as key, 'true' as value FROM feature_flags WHERE enabled = 1;

-- Get configs with type conversion
-- SELECT key,
--        CASE
--          WHEN type = 'bool' THEN CASE value WHEN '1' THEN 'true' ELSE 'false' END
--          ELSE value
--        END as value
-- FROM config;

-- Get application-specific settings
-- SELECT s.key, s.value
-- FROM settings s
-- JOIN applications a ON s.app_id = a.id
-- WHERE a.name = 'web-app' AND a.active = 1;

-- Get configs with namespace prefix
-- SELECT namespace || '_' || key as key, value FROM config;

-- Get only required configs
-- SELECT key, value FROM config WHERE required = 1;

-- Get service-specific plus shared configs
-- SELECT key, value FROM config WHERE service IS NULL OR service = 'api';

-- Get configs ordered by priority
-- SELECT key, value FROM config WHERE active = 1 ORDER BY priority DESC;
