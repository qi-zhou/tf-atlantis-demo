#!/bin/bash

# Simple setup script for Atlantis demo
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    print_status "Docker is available"
    
    # Check Docker Compose (try both old and new syntax)
    if command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker-compose"
        print_status "Docker Compose (legacy) is available"
    elif docker compose version &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker compose"
        print_status "Docker Compose (plugin) is available"
    else
        print_warning "Docker Compose not found, will use direct Docker commands"
        DOCKER_COMPOSE_CMD=""
    fi
    
    # Check ngrok
    if ! command -v ngrok &> /dev/null; then
        print_error "ngrok is not installed"
        exit 1
    fi
    print_status "ngrok is available"
    
    # Check if we're in the right directory
    if [ ! -f "atlantis.yaml" ]; then
        print_error "atlantis.yaml not found. Are you in the right directory?"
        exit 1
    fi
    print_status "In correct directory"
}

# Setup environment variables
setup_env() {
    print_header "Setting up environment variables..."
    
    if [ ! -f ".env" ]; then
        print_status "Creating .env file from template..."
        cp .env.example .env
        
        print_warning "Please edit .env file with your GitHub credentials:"
        echo "  - ATLANTIS_GH_USER: Your GitHub username"
        echo "  - ATLANTIS_GH_TOKEN: Your GitHub personal access token"
        echo "  - ATLANTIS_GH_WEBHOOK_SECRET: A random secret string"
        echo ""
        read -p "Press Enter after you've edited the .env file..."
    else
        print_status ".env file already exists"
    fi
    
    # Source the .env file
    if [ -f ".env" ]; then
        set -a
        source .env
        set +a
        print_status "Environment variables loaded"
    fi
}

# Start ngrok
start_ngrok() {
    print_header "Starting ngrok..."
    
    # Check if ngrok is already running on port 4141
    if pgrep -f "ngrok.*4141" > /dev/null; then
        print_warning "ngrok appears to be already running on port 4141"
        print_status "If you need to restart ngrok, kill the existing process first"
        return
    fi
    
    print_status "Starting ngrok in background..."
    nohup ngrok http 4141 > ngrok.log 2>&1 &
    
    # Wait for ngrok to start
    sleep 3
    
    # Get ngrok URL
    NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o 'https://[^"]*\.ngrok\.io')
    
    if [ -n "$NGROK_URL" ]; then
        print_status "ngrok started successfully!"
        print_status "Public URL: $NGROK_URL"
        
        # Update .env file with ngrok URL
        if grep -q "ATLANTIS_ATLANTIS_URL" .env; then
            sed -i.bak "s|ATLANTIS_ATLANTIS_URL=.*|ATLANTIS_ATLANTIS_URL=$NGROK_URL|" .env
        else
            echo "ATLANTIS_ATLANTIS_URL=$NGROK_URL" >> .env
        fi
        print_status "Updated .env file with ngrok URL"
        
        echo ""
        print_warning "IMPORTANT: Configure GitHub webhook with this URL:"
        echo "  Webhook URL: $NGROK_URL/events"
        echo "  Content type: application/json"
        echo "  Secret: (use the value from ATLANTIS_GH_WEBHOOK_SECRET in .env)"
        echo "  Events: Pull requests, Issue comments"
        echo ""
    else
        print_error "Failed to get ngrok URL"
        exit 1
    fi
}

# Start Atlantis
start_atlantis() {
    print_header "Starting Atlantis..."

    if [ -n "$DOCKER_COMPOSE_CMD" ]; then
        # Use Docker Compose
        print_status "Pulling Atlantis Docker image..."
        $DOCKER_COMPOSE_CMD pull

        print_status "Starting Atlantis container..."
        $DOCKER_COMPOSE_CMD up -d
    else
        # Use direct Docker commands
        print_status "Pulling Atlantis Docker image..."
        docker pull ghcr.io/runatlantis/atlantis:latest

        # Stop existing container if running
        docker stop atlantis-demo 2>/dev/null || true
        docker rm atlantis-demo 2>/dev/null || true

        print_status "Starting Atlantis container..."
        docker run -d \
            --name atlantis-demo \
            -p 4141:4141 \
            -v "$(pwd)/atlantis.yaml:/etc/atlantis/atlantis.yaml:ro" \
            -v atlantis-data:/atlantis-data \
            --env-file .env \
            ghcr.io/runatlantis/atlantis:latest \
            server --config=/etc/atlantis/atlantis.yaml
    fi

    # Wait for Atlantis to start
    print_status "Waiting for Atlantis to start..."
    sleep 10

    # Check if Atlantis is healthy
    if curl -s http://localhost:4141/healthz > /dev/null; then
        print_status "Atlantis is running and healthy!"
    else
        print_warning "Atlantis may still be starting up..."
        if [ -n "$DOCKER_COMPOSE_CMD" ]; then
            print_status "Check logs with: $DOCKER_COMPOSE_CMD logs -f atlantis-demo"
        else
            print_status "Check logs with: docker logs -f atlantis-demo"
        fi
    fi
}

# Show status
show_status() {
    print_header "Setup Summary"
    
    echo ""
    print_status "Services Status:"
    
    # Check ngrok
    if pgrep -f "ngrok.*4141" > /dev/null; then
        NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o 'https://[^"]*\.ngrok\.io')
        echo "  ✅ ngrok: Running ($NGROK_URL)"
    else
        echo "  ❌ ngrok: Not running"
    fi
    
    # Check Atlantis
    if docker ps | grep -q "atlantis-demo"; then
        echo "  ✅ Atlantis: Running (http://localhost:4141)"
    else
        echo "  ❌ Atlantis: Not running"
    fi
    
    echo ""
    print_status "Next Steps:"
    echo "  1. Configure GitHub webhook (see URL above)"
    echo "  2. Create a test branch and PR"
    echo "  3. Use 'atlantis plan' and 'atlantis apply' in PR comments"
    echo ""
    print_status "Useful Commands:"
    if [ -n "$DOCKER_COMPOSE_CMD" ]; then
        echo "  - View Atlantis logs: $DOCKER_COMPOSE_CMD logs -f atlantis-demo"
        echo "  - Stop services: $DOCKER_COMPOSE_CMD down"
    else
        echo "  - View Atlantis logs: docker logs -f atlantis-demo"
        echo "  - Stop services: docker stop atlantis-demo"
    fi
    echo "  - View ngrok dashboard: http://localhost:4040"
}

# Main function
main() {
    print_header "Atlantis Demo Setup"
    echo ""
    
    check_prerequisites
    setup_env
    start_ngrok
    start_atlantis
    show_status
    
    print_header "Setup completed! 🎉"
}

# Handle cleanup on exit
cleanup() {
    if [ "$1" != "0" ]; then
        print_error "Setup failed!"
        print_status "To clean up, run:"
        echo "  docker stop atlantis-demo 2>/dev/null || true"
        echo "  pkill -f ngrok"
    fi
}

trap 'cleanup $?' EXIT

# Run main function
main "$@"
