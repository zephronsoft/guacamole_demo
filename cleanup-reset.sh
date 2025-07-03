#!/bin/bash

# 🧹 FSBook Guacamole - Complete Reset & Cleanup Script
# This script will clean up everything and reset to initial state

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 FSBook Guacamole - Complete Reset & Cleanup Script${NC}"
echo -e "${BLUE}=======================================================${NC}"
echo

# Function to print colored output
print_step() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

# Function to ask for confirmation
confirm() {
    read -p "$(echo -e ${YELLOW}$1${NC}) [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Operation cancelled${NC}"
        exit 1
    fi
}

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
}

# Function to stop all FSBook containers
stop_containers() {
    print_step "Stopping all FSBook containers..."
    
    # Stop using docker-compose if file exists
    if [ -f "docker-compose.yml" ]; then
        docker-compose down 2>/dev/null || true
    fi
    
    # Stop any remaining FSBook containers
    FSBOOK_CONTAINERS=$(docker ps -a --filter "name=fsbook" --format "{{.Names}}" 2>/dev/null || true)
    if [ ! -z "$FSBOOK_CONTAINERS" ]; then
        echo "$FSBOOK_CONTAINERS" | xargs -r docker stop 2>/dev/null || true
        echo "$FSBOOK_CONTAINERS" | xargs -r docker rm 2>/dev/null || true
    fi
    
    # Stop containers with guacamole in name
    GUACAMOLE_CONTAINERS=$(docker ps -a --filter "name=guacamole" --format "{{.Names}}" 2>/dev/null || true)
    if [ ! -z "$GUACAMOLE_CONTAINERS" ]; then
        echo "$GUACAMOLE_CONTAINERS" | xargs -r docker stop 2>/dev/null || true
        echo "$GUACAMOLE_CONTAINERS" | xargs -r docker rm 2>/dev/null || true
    fi
    
    print_step "All containers stopped and removed"
}

# Function to remove FSBook images
remove_images() {
    print_step "Removing FSBook Docker images..."
    
    # Remove FSBook images
    FSBOOK_IMAGES=$(docker images --filter "reference=fsbook/*" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null || true)
    if [ ! -z "$FSBOOK_IMAGES" ]; then
        echo "$FSBOOK_IMAGES" | xargs -r docker rmi -f 2>/dev/null || true
    fi
    
    # Remove Guacamole images
    GUACAMOLE_IMAGES=$(docker images --filter "reference=*guacamole*" --format "{{.Repository}}:{{.Tag}}" 2>/dev/null || true)
    if [ ! -z "$GUACAMOLE_IMAGES" ]; then
        echo "$GUACAMOLE_IMAGES" | xargs -r docker rmi -f 2>/dev/null || true
    fi
    
    print_step "Docker images removed"
}

# Function to remove volumes
remove_volumes() {
    print_step "Removing Docker volumes..."
    
    # Remove FSBook volumes
    FSBOOK_VOLUMES=$(docker volume ls --filter "name=fsbook" --format "{{.Name}}" 2>/dev/null || true)
    if [ ! -z "$FSBOOK_VOLUMES" ]; then
        echo "$FSBOOK_VOLUMES" | xargs -r docker volume rm 2>/dev/null || true
    fi
    
    # Remove Guacamole volumes
    GUACAMOLE_VOLUMES=$(docker volume ls --filter "name=guacamole" --format "{{.Name}}" 2>/dev/null || true)
    if [ ! -z "$GUACAMOLE_VOLUMES" ]; then
        echo "$GUACAMOLE_VOLUMES" | xargs -r docker volume rm 2>/dev/null || true
    fi
    
    print_step "Docker volumes removed"
}

# Function to remove networks
remove_networks() {
    print_step "Removing Docker networks..."
    
    # Remove FSBook networks
    FSBOOK_NETWORKS=$(docker network ls --filter "name=fsbook" --format "{{.Name}}" 2>/dev/null || true)
    if [ ! -z "$FSBOOK_NETWORKS" ]; then
        echo "$FSBOOK_NETWORKS" | xargs -r docker network rm 2>/dev/null || true
    fi
    
    print_step "Docker networks removed"
}

# Function to clean up files
cleanup_files() {
    print_step "Cleaning up generated files..."
    
    # Remove generated SQL files
    rm -f init/01-initdb.sql 2>/dev/null || true
    rm -f init/02-setup-connections.sql 2>/dev/null || true
    rm -f init/03-create-connections.sql 2>/dev/null || true
    
    # Remove docker-compose override file
    rm -f docker-compose.override.yml 2>/dev/null || true
    
    # Remove temporary files
    rm -f guacamole-auth-jdbc-*.tar.gz 2>/dev/null || true
    rm -rf guacamole-auth-jdbc-* 2>/dev/null || true
    
    # Remove log files
    rm -f *.log 2>/dev/null || true
    
    print_step "Generated files cleaned up"
}

# Function to perform Docker system cleanup
docker_system_cleanup() {
    print_step "Performing Docker system cleanup..."
    
    # Remove unused containers, networks, images, and build cache
    docker system prune -f 2>/dev/null || true
    
    # Remove unused volumes
    docker volume prune -f 2>/dev/null || true
    
    print_step "Docker system cleanup completed"
}

# Function to show cleanup options
show_options() {
    echo -e "${BLUE}Choose cleanup level:${NC}"
    echo -e "${YELLOW}1) Quick Reset${NC} - Stop containers, remove FSBook images and volumes"
    echo -e "${YELLOW}2) Full Reset${NC} - Everything in Quick + cleanup files and networks"
    echo -e "${YELLOW}3) Nuclear Reset${NC} - Everything + Docker system cleanup (removes all unused Docker resources)"
    echo -e "${YELLOW}4) Custom Cleanup${NC} - Choose specific components to clean"
    echo -e "${YELLOW}5) Exit${NC}"
    echo
}

# Function for custom cleanup
custom_cleanup() {
    echo -e "${BLUE}Custom Cleanup Options:${NC}"
    echo
    
    confirm "Stop and remove all FSBook containers?"
    stop_containers
    
    confirm "Remove FSBook Docker images?"
    remove_images
    
    confirm "Remove FSBook Docker volumes? (⚠️ This will delete all database data!)"
    remove_volumes
    
    confirm "Remove FSBook Docker networks?"
    remove_networks
    
    confirm "Clean up generated files?"
    cleanup_files
    
    confirm "Perform Docker system cleanup?"
    docker_system_cleanup
}

# Main execution
main() {
    check_docker
    
    # Check if we're in the right directory
    if [ ! -f "docker-compose.yml" ]; then
        print_warning "docker-compose.yml not found. Make sure you're in the FSBook Guacamole directory."
        print_info "Current directory: $(pwd)"
        confirm "Continue anyway?"
    fi
    
    while true; do
        show_options
        read -p "Enter your choice [1-5]: " choice
        
        case $choice in
            1)
                echo -e "${YELLOW}🔄 Quick Reset selected${NC}"
                confirm "This will stop containers and remove FSBook images/volumes. Continue?"
                stop_containers
                remove_images
                remove_volumes
                print_step "Quick reset completed! ✨"
                break
                ;;
            2)
                echo -e "${YELLOW}🔄 Full Reset selected${NC}"
                confirm "This will remove containers, images, volumes, networks, and files. Continue?"
                stop_containers
                remove_images
                remove_volumes
                remove_networks
                cleanup_files
                print_step "Full reset completed! ✨"
                break
                ;;
            3)
                echo -e "${RED}☢️ Nuclear Reset selected${NC}"
                print_warning "This will remove ALL unused Docker resources (not just FSBook)"
                confirm "Are you ABSOLUTELY sure? This affects ALL Docker resources!"
                stop_containers
                remove_images
                remove_volumes
                remove_networks
                cleanup_files
                docker_system_cleanup
                print_step "Nuclear reset completed! ✨"
                break
                ;;
            4)
                echo -e "${YELLOW}🎯 Custom Cleanup selected${NC}"
                custom_cleanup
                print_step "Custom cleanup completed! ✨"
                break
                ;;
            5)
                echo -e "${GREEN}👋 Goodbye!${NC}"
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please select 1-5."
                ;;
        esac
    done
    
    echo
    print_step "🎉 Cleanup completed successfully!"
    print_info "You can now run './complete-fsbook-setup.sh' to set up everything from scratch."
    echo
}

# Run main function
main "$@" 