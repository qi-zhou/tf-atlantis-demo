#!/bin/bash

# Stop Atlantis Server Script

set -e

echo "🛑 Stopping Atlantis Server"
echo "=========================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Stop Atlantis container
echo -e "${BLUE}🛑 Stopping Atlantis container...${NC}"
if docker stop atlantis-demo 2>/dev/null; then
    echo -e "${GREEN}✅ Atlantis container stopped${NC}"
else
    echo -e "${YELLOW}⚠️  Atlantis container was not running${NC}"
fi

# Remove Atlantis container
echo -e "${BLUE}🗑️  Removing Atlantis container...${NC}"
if docker rm atlantis-demo 2>/dev/null; then
    echo -e "${GREEN}✅ Atlantis container removed${NC}"
else
    echo -e "${YELLOW}⚠️  Atlantis container was already removed${NC}"
fi

# Check for running ngrok processes
echo -e "${BLUE}🔍 Checking for ngrok processes...${NC}"
NGROK_PIDS=$(pgrep ngrok 2>/dev/null || true)
if [ -n "$NGROK_PIDS" ]; then
    echo -e "${YELLOW}⚠️  Found running ngrok processes: $NGROK_PIDS${NC}"
    echo -e "${BLUE}💡 To stop ngrok, run: pkill ngrok${NC}"
else
    echo -e "${GREEN}✅ No ngrok processes found${NC}"
fi

echo -e "${GREEN}🎉 Cleanup completed!${NC}"
