#!/bin/bash

# Atlantis Demo Script
# This script demonstrates the Atlantis workflow without requiring Docker

set -e

echo "🌊 Atlantis Demo - Terraform Automation Workflow"
echo "================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "\n${BLUE}📋 Checking Prerequisites...${NC}"

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${YELLOW}⚠️  Terraform not found. Installing via Homebrew...${NC}"
    if command -v brew &> /dev/null; then
        brew install terraform
    else
        echo -e "${RED}❌ Homebrew not found. Please install Terraform manually.${NC}"
        exit 1
    fi
fi

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
    echo -e "${YELLOW}⚠️  ngrok not found. Installing via Homebrew...${NC}"
    if command -v brew &> /dev/null; then
        brew install ngrok
    else
        echo -e "${RED}❌ Homebrew not found. Please install ngrok manually.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Prerequisites check completed${NC}"

# Initialize Terraform
echo -e "\n${BLUE}🔧 Initializing Terraform...${NC}"
cd terraform
terraform init

# Validate Terraform configuration
echo -e "\n${BLUE}🔍 Validating Terraform configuration...${NC}"
terraform validate

# Format Terraform files
echo -e "\n${BLUE}📝 Formatting Terraform files...${NC}"
terraform fmt

# Show Terraform plan
echo -e "\n${BLUE}📋 Running Terraform Plan...${NC}"
terraform plan

echo -e "\n${GREEN}✅ Terraform validation completed successfully!${NC}"

cd ..

# Start ngrok in background
echo -e "\n${BLUE}🌐 Starting ngrok tunnel...${NC}"
ngrok http 4141 > ngrok.log 2>&1 &
NGROK_PID=$!

# Wait for ngrok to start
sleep 3

# Get ngrok URL
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for tunnel in data['tunnels']:
        if tunnel['proto'] == 'https':
            print(tunnel['public_url'])
            break
except:
    print('Error getting ngrok URL')
")

if [ -z "$NGROK_URL" ]; then
    echo -e "${RED}❌ Failed to get ngrok URL${NC}"
    kill $NGROK_PID 2>/dev/null || true
    exit 1
fi

echo -e "${GREEN}✅ ngrok tunnel started: ${NGROK_URL}${NC}"

# Update environment with ngrok URL
sed -i.bak "s|ATLANTIS_ATLANTIS_URL=.*|ATLANTIS_ATLANTIS_URL=${NGROK_URL}|" .env

echo -e "\n${BLUE}📝 Updated .env file with ngrok URL${NC}"

# Simulate Atlantis workflow
echo -e "\n${BLUE}🌊 Simulating Atlantis Workflow...${NC}"

echo -e "\n${YELLOW}📋 Step 1: Pull Request Created${NC}"
echo "   - Developer creates PR with Terraform changes"
echo "   - GitHub webhook triggers Atlantis"
echo "   - Atlantis automatically runs 'terraform plan'"

echo -e "\n${YELLOW}💬 Step 2: Plan Comment${NC}"
echo "   - Atlantis posts plan results as PR comment"
echo "   - Team reviews the planned changes"

echo -e "\n${YELLOW}✅ Step 3: Apply Approval${NC}"
echo "   - Team member comments 'atlantis apply'"
echo "   - Atlantis runs 'terraform apply'"
echo "   - Infrastructure changes are deployed"

echo -e "\n${GREEN}🎉 Demo completed successfully!${NC}"

# Show configuration summary
echo -e "\n${BLUE}📊 Configuration Summary:${NC}"
echo "   Repository: github.com/qi-zhou/tf-atlantis-demo"
echo "   Webhook URL: ${NGROK_URL}/events"
echo "   Local Port: 4141"
echo "   Terraform Dir: ./terraform"

echo -e "\n${BLUE}🔧 Next Steps:${NC}"
echo "   1. Configure GitHub webhook:"
echo "      - URL: ${NGROK_URL}/events"
echo "      - Content type: application/json"
echo "      - Events: Pull requests, Issue comments"
echo "      - Secret: my-webhook-secret-123"
echo ""
echo "   2. Create a test PR with Terraform changes"
echo "   3. Comment 'atlantis plan' to trigger planning"
echo "   4. Comment 'atlantis apply' to apply changes"

echo -e "\n${YELLOW}📝 To stop the demo:${NC}"
echo "   - Press Ctrl+C to stop ngrok"
echo "   - Run: kill $NGROK_PID"

# Keep ngrok running
echo -e "\n${GREEN}🌊 Atlantis demo is running...${NC}"
echo -e "${BLUE}Press Ctrl+C to stop${NC}"

# Trap to cleanup on exit
trap 'echo -e "\n${YELLOW}🛑 Stopping demo...${NC}"; kill $NGROK_PID 2>/dev/null || true; exit 0' INT

# Wait for user to stop
wait $NGROK_PID
