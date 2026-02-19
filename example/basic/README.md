# Basic Filtering Examples

This directory demonstrates different configuration organization patterns and how to use `cfg2env` filtering to extract exactly what you need.

## Configuration Patterns

We provide three organizational patterns for the same configuration data:

### 1. **config-by-env.yaml** - `ENV_SERVICE_KEY` Pattern
Organized by environment first. Best for deploying entire environments.

```yaml
dev:
  database:
    host: localhost
    password: dev_pass
staging:
  database:
    host: staging-db.internal
```

**Output keys:** `DEV_DATABASE_HOST`, `DEV_DATABASE_PASSWORD`, `STAGING_DATABASE_HOST`

### 2. **config-by-service.yaml** - `SERVICE_ENV_KEY` Pattern
Organized by service first. Best for managing service configs across environments.

```yaml
database:
  dev:
    host: localhost
  staging:
    host: staging-db.internal
```

**Output keys:** `DATABASE_DEV_HOST`, `DATABASE_STAGING_HOST`

### 3. **config-by-key.yaml** - `SERVICE_KEY_ENV` Pattern
Flat structure with environment as suffix. Best for comparing settings across environments.

```yaml
database_host_dev: localhost
database_host_staging: staging-db.internal
```

**Output keys:** `DATABASE_HOST_DEV`, `DATABASE_HOST_STAGING`

## Filtering Examples

### Extract Entire Environment

```bash
# Get all dev environment config
cat config-by-env.yaml | cfg2env --include "DEV_*" > dev.env

# Get all prod environment config
cat config-by-env.yaml | cfg2env --include "PROD_*" > prod.env
```

### Extract Specific Service

```bash
# Get all database configs (across all environments)
cat config-by-service.yaml | cfg2env --include "DATABASE_*" > database.env

# Get all API configs (across all environments)
cat config-by-service.yaml | cfg2env --include "API_*" > api.env
```

### Extract Service + Environment Combo

```bash
# Pattern: ENV_SERVICE_KEY
cat config-by-env.yaml | cfg2env --include "DEV_DATABASE_*" > dev-database.env

# Pattern: SERVICE_ENV_KEY
cat config-by-service.yaml | cfg2env --include "DATABASE_DEV_*" > database-dev.env

# Pattern: SERVICE_KEY_ENV
cat config-by-key.yaml | cfg2env --include "*_DEV" > all-dev-settings.env
```

### Exclude Sensitive Data

```bash
# Production config without secrets
cat config-by-env.yaml | cfg2env \
  --include "PROD_*" \
  --exclude "*_PASSWORD,*_SECRET,*_API_KEY" > prod-public.env

# All database configs without passwords
cat config-by-service.yaml | cfg2env \
  --include "DATABASE_*" \
  --exclude "*_PASSWORD" > database-public.env
```

### Multi-Service, Single Environment

```bash
# Dev config for database and cache only
cat config-by-env.yaml | cfg2env \
  --include "DEV_DATABASE_*,DEV_CACHE_*" > dev-data-services.env

# Prod API and queue configs
cat config-by-env.yaml | cfg2env \
  --include "PROD_API_*,PROD_QUEUE_*" > prod-messaging.env
```

### Cross-Environment Comparison

```bash
# Compare database hosts across all environments
cat config-by-key.yaml | cfg2env --include "DATABASE_HOST_*"

# Compare all staging settings
cat config-by-key.yaml | cfg2env --include "*_STAGING"
```

## Practical Use Cases

### Use Case 1: CI/CD Pipeline - Environment-Specific Deployment

```bash
#!/bin/bash
ENV=$1  # dev, staging, prod

# Generate environment-specific .env file
cat config-by-env.yaml | cfg2env --include "${ENV^^}_*" > .env

# Deploy with docker-compose
docker-compose up -d
```

### Use Case 2: Service-Specific Configuration

```bash
#!/bin/bash
SERVICE=$1  # database, api, cache, queue

# Extract service config across all environments
cat config-by-service.yaml | cfg2env --include "${SERVICE^^}_*" > ${SERVICE}.env

# Or get service config for specific environment
cat config-by-service.yaml | cfg2env \
  --include "${SERVICE^^}_PROD_*" > ${SERVICE}-prod.env
```

### Use Case 3: Security - Public vs Private Configs

```bash
# Generate public config (no secrets) for documentation
cat config-by-env.yaml | cfg2env \
  --exclude "*_PASSWORD,*_SECRET,*_API_KEY,*_TOKEN" > config-public.env

# Generate secrets-only file (separate secure storage)
cat config-by-env.yaml | cfg2env \
  --include "*_PASSWORD,*_SECRET,*_API_KEY" > secrets.env
```

### Use Case 4: Debugging - Compare Environments

```bash
# Extract same service settings from different environments for comparison
cat config-by-service.yaml | cfg2env --include "DATABASE_DEV_*" > /tmp/db-dev.env
cat config-by-service.yaml | cfg2env --include "DATABASE_PROD_*" > /tmp/db-prod.env
diff /tmp/db-dev.env /tmp/db-prod.env
```

## Pattern Selection Guide

**Choose `ENV_SERVICE_KEY` (config-by-env.yaml) when:**
- Deploying entire environments at once
- Environment isolation is primary concern
- Each environment has distinct infrastructure

**Choose `SERVICE_ENV_KEY` (config-by-service.yaml) when:**
- Managing microservices independently
- Updating service config across all environments
- Service-centric operations

**Choose `SERVICE_KEY_ENV` (config-by-key.yaml) when:**
- Comparing configurations across environments
- Flat structure is preferred
- Easy visual scanning of differences

## Try It Yourself

```bash
# Navigate to this directory
cd example/basic

# Run any of the examples above, for instance:
cat config-by-env.yaml | ../../cfg2env --include "DEV_*"
cat config-by-service.yaml | ../../cfg2env --include "DATABASE_*" --exclude "*_PASSWORD"
cat config-by-key.yaml | ../../cfg2env --include "*_PROD"
```

## Tips

- **Pattern matching is case-insensitive**: `--include "dev_*"` works same as `"DEV_*"`
- **Combine multiple patterns with commas**: `--include "DEV_*,STAGING_*"`
- **Include happens first, then exclude**: Use include to whitelist, exclude to blacklist
- **No matches returns empty file with comment**: Makes debugging filter patterns easy