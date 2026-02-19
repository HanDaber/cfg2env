#!/bin/sh
# Real-world use cases for cfg2env with SQLite
# This demonstrates practical scenarios you might encounter

set -e

echo "=== cfg2env SQLite: Real-World Use Cases ==="
echo

# Use Case 1: Database-Backed Application Configuration
echo "Use Case 1: Database-Backed Application Configuration"
echo "------------------------------------------------------"
echo "Scenario: Your application stores config in a database and you need"
echo "          to extract it as environment variables for deployment"
echo

sqlite3 app-config.db << 'SQL'
CREATE TABLE application_config (
  config_key TEXT PRIMARY KEY,
  config_value TEXT NOT NULL,
  last_updated DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO application_config (config_key, config_value) VALUES
  ('DATABASE_URL', 'postgresql://user:pass@localhost:5432/mydb'),
  ('REDIS_URL', 'redis://localhost:6379/0'),
  ('SECRET_KEY', 'django-insecure-key-123'),
  ('ALLOWED_HOSTS', 'example.com,www.example.com'),
  ('DEBUG', 'False'),
  ('EMAIL_HOST', 'smtp.gmail.com'),
  ('EMAIL_PORT', '587');
SQL

cat app-config.db | cfg2env --format sqlite \
  --query "SELECT config_key as key, config_value as value FROM application_config" \
  > app.env

echo "✓ Extracted application config to app.env"
cat app.env
echo

# Use Case 2: Docker Compose Environment Generation
echo "Use Case 2: Docker Compose Environment Generation"
echo "---------------------------------------------------"
echo "Scenario: Generate .env files for docker-compose from a centralized"
echo "          configuration database"
echo

sqlite3 docker-configs.db << 'SQL'
CREATE TABLE container_config (
  id INTEGER PRIMARY KEY,
  service_name TEXT NOT NULL,
  env_key TEXT NOT NULL,
  env_value TEXT NOT NULL,
  UNIQUE(service_name, env_key)
);

INSERT INTO container_config (service_name, env_key, env_value) VALUES
  ('web', 'PORT', '8000'),
  ('web', 'WORKERS', '4'),
  ('web', 'LOG_LEVEL', 'info'),
  ('db', 'POSTGRES_USER', 'appuser'),
  ('db', 'POSTGRES_PASSWORD', 'secret'),
  ('db', 'POSTGRES_DB', 'appdb'),
  ('redis', 'REDIS_PASSWORD', 'redis_secret');
SQL

# Extract per-service configs
for service in web db redis; do
  cat docker-configs.db | cfg2env --format sqlite \
    --query "SELECT env_key as key, env_value as value FROM container_config WHERE service_name = '${service}'" \
    > ".env.${service}"
  echo "✓ Generated .env.${service}"
done
echo

# Use Case 3: CI/CD Pipeline Configuration
echo "Use Case 3: CI/CD Pipeline Configuration"
echo "------------------------------------------"
echo "Scenario: Different CI/CD stages need different configurations"
echo

sqlite3 ci-config.db << 'SQL'
CREATE TABLE pipeline_config (
  id INTEGER PRIMARY KEY,
  stage TEXT NOT NULL,
  variable_name TEXT NOT NULL,
  variable_value TEXT NOT NULL,
  UNIQUE(stage, variable_name)
);

INSERT INTO pipeline_config (stage, variable_name, variable_value) VALUES
  ('build', 'NODE_ENV', 'production'),
  ('build', 'BUILD_NUMBER', '${CI_PIPELINE_ID}'),
  ('build', 'CACHE_ENABLED', 'true'),
  ('test', 'NODE_ENV', 'test'),
  ('test', 'TEST_TIMEOUT', '300'),
  ('test', 'PARALLEL_TESTS', '4'),
  ('deploy', 'DEPLOYMENT_ENV', 'production'),
  ('deploy', 'HEALTH_CHECK_URL', 'https://api.example.com/health'),
  ('deploy', 'ROLLBACK_ENABLED', 'true');
SQL

for stage in build test deploy; do
  cat ci-config.db | cfg2env --format sqlite \
    --query "SELECT variable_name as key, variable_value as value FROM pipeline_config WHERE stage = '${stage}'" \
    > "ci.${stage}.env"
  echo "✓ Generated ci.${stage}.env"
done
echo

# Use Case 4: Feature Flag Management
echo "Use Case 4: Feature Flag Management"
echo "-------------------------------------"
echo "Scenario: Export enabled features as environment variables for runtime checks"
echo

sqlite3 feature-management.db << 'SQL'
CREATE TABLE features (
  id INTEGER PRIMARY KEY,
  feature_name TEXT UNIQUE NOT NULL,
  enabled BOOLEAN DEFAULT 0,
  environment TEXT DEFAULT 'all',
  rollout_percent INTEGER DEFAULT 100
);

INSERT INTO features (feature_name, enabled, environment, rollout_percent) VALUES
  ('FEATURE_NEW_DASHBOARD', 1, 'all', 100),
  ('FEATURE_BETA_API', 1, 'staging', 50),
  ('FEATURE_EXPERIMENTAL_SEARCH', 0, 'all', 0),
  ('FEATURE_DARK_MODE', 1, 'all', 100),
  ('FEATURE_ANALYTICS', 1, 'production', 100),
  ('FEATURE_DEBUG_TOOLBAR', 1, 'development', 100);
SQL

# Export all enabled features
cat feature-management.db | cfg2env --format sqlite \
  --query "SELECT feature_name as key, 'enabled' as value FROM features WHERE enabled = 1" \
  > features.env

echo "✓ Generated features.env with enabled features"
cat features.env
echo

# Export production-ready features only
cat feature-management.db | cfg2env --format sqlite \
  --query "SELECT feature_name as key, 'enabled' as value FROM features WHERE enabled = 1 AND environment IN ('all', 'production')" \
  > features.production.env

echo "✓ Generated features.production.env"
cat features.production.env
echo

# Use Case 5: Multi-Tenant Configuration
echo "Use Case 5: Multi-Tenant Configuration"
echo "----------------------------------------"
echo "Scenario: Extract tenant-specific configuration from a shared database"
echo

sqlite3 tenants.db << 'SQL'
CREATE TABLE tenant_configs (
  id INTEGER PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  config_key TEXT NOT NULL,
  config_value TEXT NOT NULL,
  UNIQUE(tenant_id, config_key)
);

INSERT INTO tenant_configs (tenant_id, config_key, config_value) VALUES
  ('acme-corp', 'TENANT_NAME', 'Acme Corporation'),
  ('acme-corp', 'MAX_USERS', '100'),
  ('acme-corp', 'STORAGE_LIMIT_GB', '500'),
  ('acme-corp', 'API_RATE_LIMIT', '10000'),
  ('techstart', 'TENANT_NAME', 'TechStart Inc'),
  ('techstart', 'MAX_USERS', '50'),
  ('techstart', 'STORAGE_LIMIT_GB', '100'),
  ('techstart', 'API_RATE_LIMIT', '5000');
SQL

for tenant in acme-corp techstart; do
  cat tenants.db | cfg2env --format sqlite \
    --query "SELECT config_key as key, config_value as value FROM tenant_configs WHERE tenant_id = '${tenant}'" \
    > "tenant.${tenant}.env"
  echo "✓ Generated tenant.${tenant}.env"
done
echo

# Use Case 6: Secret Rotation Workflow
echo "Use Case 6: Secret Rotation with Version Tracking"
echo "---------------------------------------------------"
echo "Scenario: Track and export the latest version of secrets"
echo

sqlite3 secrets.db << 'SQL'
CREATE TABLE secrets (
  id INTEGER PRIMARY KEY,
  secret_name TEXT NOT NULL,
  secret_value TEXT NOT NULL,
  version INTEGER NOT NULL,
  active BOOLEAN DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(secret_name, version)
);

INSERT INTO secrets (secret_name, secret_value, version, active) VALUES
  ('API_KEY', 'sk_live_old_key', 1, 0),
  ('API_KEY', 'sk_live_new_key', 2, 1),
  ('DB_PASSWORD', 'old_password', 1, 0),
  ('DB_PASSWORD', 'new_secure_password', 2, 1),
  ('JWT_SECRET', 'jwt_secret_v1', 1, 1);
SQL

# Export only active secrets (latest versions)
cat secrets.db | cfg2env --format sqlite \
  --query "SELECT secret_name as key, secret_value as value FROM secrets WHERE active = 1" \
  > secrets.env

echo "✓ Generated secrets.env with active secrets only"
cat secrets.env
echo

# Use Case 7: Microservices Configuration Matrix
echo "Use Case 7: Microservices Configuration Matrix"
echo "------------------------------------------------"
echo "Scenario: Shared base config + service-specific overrides"
echo

sqlite3 microservices.db << 'SQL'
CREATE TABLE service_config (
  id INTEGER PRIMARY KEY,
  service TEXT,  -- NULL = shared
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  priority INTEGER DEFAULT 0
);

INSERT INTO service_config (service, key, value, priority) VALUES
  -- Shared configs
  (NULL, 'LOG_FORMAT', 'json', 10),
  (NULL, 'LOG_LEVEL', 'info', 10),
  (NULL, 'ENVIRONMENT', 'production', 10),
  (NULL, 'REGION', 'us-east-1', 10),
  -- API service
  ('api', 'SERVICE_NAME', 'api', 20),
  ('api', 'PORT', '8080', 20),
  ('api', 'LOG_LEVEL', 'debug', 20),  -- Override shared
  -- Worker service
  ('worker', 'SERVICE_NAME', 'worker', 20),
  ('worker', 'CONCURRENCY', '10', 20),
  ('worker', 'QUEUE_NAME', 'default', 20);
SQL

# Extract shared + service-specific with priority
for service in api worker; do
  cat microservices.db | cfg2env --format sqlite \
    --query "SELECT key, value FROM service_config WHERE service IS NULL OR service = '${service}' ORDER BY key, priority" \
    > "service.${service}.env"
  echo "✓ Generated service.${service}.env (shared + specific)"
done
echo

cat service.api.env
echo

# Use Case 8: Configuration Compliance Export
echo "Use Case 8: Configuration Compliance Export"
echo "---------------------------------------------"
echo "Scenario: Export only approved/validated configurations"
echo

sqlite3 compliance.db << 'SQL'
CREATE TABLE approved_config (
  id INTEGER PRIMARY KEY,
  key TEXT UNIQUE NOT NULL,
  value TEXT NOT NULL,
  approved_by TEXT NOT NULL,
  approved_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  compliant BOOLEAN DEFAULT 1,
  audit_required BOOLEAN DEFAULT 0
);

INSERT INTO approved_config (key, value, approved_by, compliant, audit_required) VALUES
  ('ENCRYPTION_ENABLED', 'true', 'security-team', 1, 1),
  ('MIN_TLS_VERSION', '1.2', 'security-team', 1, 1),
  ('PASSWORD_MIN_LENGTH', '12', 'security-team', 1, 1),
  ('SESSION_TIMEOUT', '900', 'security-team', 1, 1),
  ('AUDIT_LOGGING', 'true', 'compliance-team', 1, 1),
  ('DATA_RETENTION_DAYS', '90', 'compliance-team', 1, 1);
SQL

cat compliance.db | cfg2env --format sqlite \
  --query "SELECT key, value FROM approved_config WHERE compliant = 1" \
  > compliance.env

echo "✓ Generated compliance.env with approved settings only"
cat compliance.env
echo

# Summary
echo "=========================================="
echo "Use Cases Summary"
echo "=========================================="
echo "Generated files:"
ls -1 *.env *.db | grep -E "\\.env$|\\.db$" | sort
echo
echo "All use cases completed successfully!"
echo
echo "Integration examples:"
echo "  # Load into Docker container"
echo "  docker run --env-file app.env myimage:latest"
echo
echo "  # Source in shell"
echo "  set -a; source app.env; set +a"
echo
echo "  # Use in docker-compose"
echo "  docker-compose --env-file service.api.env up"
echo
echo "  # Deploy to Kubernetes"
echo "  kubectl create secret generic app-secrets --from-env-file=secrets.env"
echo

# Cleanup instructions
echo "To clean up:"
echo "  rm -f *.db *.env"
