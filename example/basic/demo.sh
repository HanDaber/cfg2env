#!/usr/bin/env bash
set -e

# demo.sh - Interactive demonstration of cfg2env filtering capabilities
# This script shows practical examples of filtering different config patterns

cd "$(dirname "$0")"
CFG2ENV="../../cfg2env"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

echo_command() {
    echo -e "\n${GREEN}$ $1${NC}"
}

pause() {
    echo -e "\n${BLUE}[Press Enter to continue]${NC}"
    read -r
}

# Check if cfg2env is built
if [ ! -f "$CFG2ENV" ]; then
    echo "Building cfg2env..."
    (cd ../.. && go build -o cfg2env)
fi

echo_header "cfg2env Filtering Demo"
echo "This demo shows how to filter configurations using different organizational patterns."

pause

# ========================================
# PATTERN 1: ENV_SERVICE_KEY
# ========================================
echo_header "Pattern 1: ENV_SERVICE_KEY (config-by-env.yaml)"
echo "Organization: environment → service → key"
echo "Best for: Deploying entire environments"

echo_command "cat config-by-env.yaml | $CFG2ENV --include 'DEV_*' | head -20"
cat config-by-env.yaml | $CFG2ENV --include "DEV_*" | head -20
echo "... (showing first 20 lines)"

pause

echo_command "cat config-by-env.yaml | $CFG2ENV --include 'DEV_DATABASE_*'"
cat config-by-env.yaml | $CFG2ENV --include "DEV_DATABASE_*"

pause

echo_command "cat config-by-env.yaml | $CFG2ENV --include 'PROD_*' --exclude '*_PASSWORD,*_SECRET,*_API_KEY' | head -20"
cat config-by-env.yaml | $CFG2ENV --include "PROD_*" --exclude "*_PASSWORD,*_SECRET,*_API_KEY" | head -20
echo "... (showing first 20 lines - no sensitive data)"

pause

# ========================================
# PATTERN 2: SERVICE_ENV_KEY
# ========================================
echo_header "Pattern 2: SERVICE_ENV_KEY (config-by-service.yaml)"
echo "Organization: service → environment → key"
echo "Best for: Managing services across environments"

echo_command "cat config-by-service.yaml | $CFG2ENV --include 'DATABASE_*'"
cat config-by-service.yaml | $CFG2ENV --include "DATABASE_*"

pause

echo_command "cat config-by-service.yaml | $CFG2ENV --include 'API_PROD_*'"
cat config-by-service.yaml | $CFG2ENV --include "API_PROD_*"

pause

echo_command "cat config-by-service.yaml | $CFG2ENV --include 'DATABASE_*,CACHE_*' --exclude '*_PASSWORD'"
cat config-by-service.yaml | $CFG2ENV --include "DATABASE_*,CACHE_*" --exclude "*_PASSWORD"

pause

# ========================================
# PATTERN 3: SERVICE_KEY_ENV
# ========================================
echo_header "Pattern 3: SERVICE_KEY_ENV (config-by-key.yaml)"
echo "Organization: service_key_environment (flat)"
echo "Best for: Comparing settings across environments"

echo_command "cat config-by-key.yaml | $CFG2ENV --include '*_DEV'"
cat config-by-key.yaml | $CFG2ENV --include "*_DEV"

pause

echo_command "cat config-by-key.yaml | $CFG2ENV --include 'DATABASE_HOST_*'"
cat config-by-key.yaml | $CFG2ENV --include "DATABASE_HOST_*"
echo "(Compare database hosts across all environments)"

pause

echo_command "cat config-by-key.yaml | $CFG2ENV --include '*_PROD' --exclude '*_PASSWORD*,*_SECRET*,*_KEY*'"
cat config-by-key.yaml | $CFG2ENV --include "*_PROD" --exclude "*_PASSWORD*,*_SECRET*,*_KEY*"

pause

# ========================================
# PRACTICAL EXAMPLES
# ========================================
echo_header "Practical Use Cases"

echo -e "\n${GREEN}Use Case 1: Generate dev.env for local development${NC}"
echo_command "cat config-by-env.yaml | $CFG2ENV --include 'DEV_*' > dev.env"
cat config-by-env.yaml | $CFG2ENV --include "DEV_*" > dev.env
echo "✓ Created dev.env ($(wc -l < dev.env | tr -d ' ') lines)"

pause

echo -e "\n${GREEN}Use Case 2: Generate database config (all environments)${NC}"
echo_command "cat config-by-service.yaml | $CFG2ENV --include 'DATABASE_*' > database-all-envs.env"
cat config-by-service.yaml | $CFG2ENV --include "DATABASE_*" > database-all-envs.env
echo "✓ Created database-all-envs.env ($(wc -l < database-all-envs.env | tr -d ' ') lines)"

pause

echo -e "\n${GREEN}Use Case 3: Generate prod config without secrets${NC}"
echo_command "cat config-by-env.yaml | $CFG2ENV --include 'PROD_*' --exclude '*_PASSWORD,*_SECRET,*_API_KEY' > prod-public.env"
cat config-by-env.yaml | $CFG2ENV --include "PROD_*" --exclude "*_PASSWORD,*_SECRET,*_API_KEY" > prod-public.env
echo "✓ Created prod-public.env ($(wc -l < prod-public.env | tr -d ' ') lines)"

pause

echo -e "\n${GREEN}Use Case 4: Empty result (no matches)${NC}"
echo_command "cat config-by-env.yaml | $CFG2ENV --include 'NONEXISTENT_*'"
cat config-by-env.yaml | $CFG2ENV --include "NONEXISTENT_*"

pause

# ========================================
# PATTERN NORMALIZATION
# ========================================
echo_header "Pattern Normalization (Case-Insensitive)"
echo "Patterns are normalized the same way as keys - uppercase + dunder processing"

echo_command "cat config-by-env.yaml | $CFG2ENV --include 'dev_database_*'"
echo "(lowercase pattern)"
cat config-by-env.yaml | $CFG2ENV --include "dev_database_*"

pause

echo_command "cat config-by-env.yaml | $CFG2ENV --include 'Dev_Database_*'"
echo "(mixed case pattern)"
cat config-by-env.yaml | $CFG2ENV --include "Dev_Database_*"

pause

# ========================================
# CLEANUP
# ========================================
echo_header "Demo Complete!"
echo "Generated files:"
ls -lh *.env 2>/dev/null || echo "No .env files to show"

echo -e "\n${GREEN}Clean up demo files? (y/n)${NC}"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    rm -f dev.env database-all-envs.env prod-public.env
    echo "✓ Cleaned up"
fi

echo -e "\n${BLUE}See README.md for more examples and use cases!${NC}"
