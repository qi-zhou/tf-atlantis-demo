#!/bin/bash

# Start Atlantis Server Script
# This script starts the Atlantis server using Docker

set -e

echo "🌊 Starting Atlantis Server"
echo "=========================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}❌ .env file not found. Please copy .env.example to .env and configure it.${NC}"
    exit 1
fi

# Load environment variables
source .env

# Validate required environment variables
if [ -z "$ATLANTIS_GH_USER" ] || [ -z "$ATLANTIS_GH_TOKEN" ] || [ -z "$ATLANTIS_GH_WEBHOOK_SECRET" ] || [ -z "$ATLANTIS_REPO_ALLOWLIST" ]; then
    echo -e "${RED}❌ Missing required environment variables. Please check your .env file.${NC}"
    echo "Required variables: ATLANTIS_GH_USER, ATLANTIS_GH_TOKEN, ATLANTIS_GH_WEBHOOK_SECRET, ATLANTIS_REPO_ALLOWLIST"
    exit 1
fi

# Stop any existing Atlantis container
echo -e "${BLUE}🛑 Stopping any existing Atlantis container...${NC}"
docker stop atlantis-demo 2>/dev/null || true
docker rm atlantis-demo 2>/dev/null || true

# Pull latest Atlantis image
echo -e "${BLUE}📥 Pulling latest Atlantis image...${NC}"
docker pull runatlantis/atlantis:latest

# Start Atlantis container
echo -e "${BLUE}🚀 Starting Atlantis server...${NC}"
docker run -d \
  --name atlantis-demo \
  -p 4141:4141 \
  -v $(pwd):/atlantis-data \
  -v $(pwd)/server-config.yaml:/etc/atlantis/repos.yaml:ro \
  -w /atlantis-data \
  -e ATLANTIS_GH_USER="$ATLANTIS_GH_USER" \
  -e ATLANTIS_GH_TOKEN="$ATLANTIS_GH_TOKEN" \
  -e ATLANTIS_GH_WEBHOOK_SECRET="$ATLANTIS_GH_WEBHOOK_SECRET" \
  -e ATLANTIS_REPO_ALLOWLIST="$ATLANTIS_REPO_ALLOWLIST" \
  -e ATLANTIS_ATLANTIS_URL="${ATLANTIS_ATLANTIS_URL:-http://localhost:4141}" \
  -e ATLANTIS_PORT=4141 \
  runatlantis/atlantis:latest \
  server \
  --atlantis-url="${ATLANTIS_ATLANTIS_URL:-http://localhost:4141}" \
  --gh-user="$ATLANTIS_GH_USER" \
  --gh-token="$ATLANTIS_GH_TOKEN" \
  --gh-webhook-secret="$ATLANTIS_GH_WEBHOOK_SECRET" \
  --repo-allowlist="$ATLANTIS_REPO_ALLOWLIST" \
  --repo-config=/etc/atlantis/repos.yaml

# Wait for container to start
sleep 3

# Check if container is running
if docker ps | grep -q atlantis-demo; then
    echo -e "${GREEN}✅ Atlantis server started successfully!${NC}"
    echo -e "${BLUE}📊 Server Information:${NC}"
    echo "   Container: atlantis-demo"
    echo "   Port: 4141"
    echo "   URL: ${ATLANTIS_ATLANTIS_URL:-http://localhost:4141}"
    echo "   Repository: $ATLANTIS_REPO_ALLOWLIST"
    echo ""
    echo -e "${BLUE}📝 Next Steps:${NC}"
    echo "   1. Configure GitHub webhook with URL: ${ATLANTIS_ATLANTIS_URL:-http://localhost:4141}/events"
    echo "   2. Create a test PR with Terraform changes"
    echo "   3. Comment 'atlantis plan' or 'atlantis apply' in the PR"
    echo ""
    echo -e "${BLUE}🔧 Useful Commands:${NC}"
    echo "   View logs: docker logs -f atlantis-demo"
    echo "   Stop server: docker stop atlantis-demo"
    echo "   Remove container: docker rm atlantis-demo"
else
    echo -e "${RED}❌ Failed to start Atlantis server${NC}"
    echo "Check logs with: docker logs atlantis-demo"
    exit 1
fi
