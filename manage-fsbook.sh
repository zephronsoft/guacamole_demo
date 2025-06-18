#!/bin/bash

# FSBook Guacamole Management Script
# Provides easy management of the FSBook developer environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

show_help() {
    echo "FSBook Guacamole Management Script"
    echo "Organization: fsbook | Project: fsbook"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  setup                    - Initial setup of Guacamole system"
    echo "  start [service]          - Start all services or specific service"
    echo "  stop [service]           - Stop all services or specific service"
    echo "  restart [service]        - Restart all services or specific service"
    echo "  status                   - Show status of all services"
    echo "  logs [service]           - Show logs for all services or specific service"
    echo "  add-dev <name> <port>    - Add a new developer container"
    echo "  remove-dev <name>        - Remove a developer container"
    echo "  list-devs                - List all developer containers"
    echo "  backup                   - Backup all developer data"
    echo "  restore                  - Restore developer data from backup"
    echo "  update                   - Update all container images"
    echo "  clean                    - Clean up unused containers and images"
    echo "  reset                    - Reset entire system (WARNING: Data loss)"
    echo ""
    echo "Examples:"
    echo "  $0 setup                 - Set up the entire system"
    echo "  $0 add-dev alice 3393    - Add developer 'alice' on port 3393"
    echo "  $0 start dev-john        - Start John's developer container"
    echo "  $0 logs guacamole        - Show Guacamole logs"
    echo "  $0 status                - Show all container status"
}

setup_system() {
    echo "🚀 Setting up FSBook Guacamole system..."
    ./setup-guacamole.sh
}

start_services() {
    if [ -z "$1" ]; then
        echo "🟢 Starting all FSBook services..."
        docker-compose up -d
    else
        echo "🟢 Starting service: $1"
        docker-compose up -d "$1"
    fi
}

stop_services() {
    if [ -z "$1" ]; then
        echo "🔴 Stopping all FSBook services..."
        docker-compose down
    else
        echo "🔴 Stopping service: $1"
        docker-compose stop "$1"
    fi
}

restart_services() {
    if [ -z "$1" ]; then
        echo "🔄 Restarting all FSBook services..."
        docker-compose restart
    else
        echo "🔄 Restarting service: $1"
        docker-compose restart "$1"
    fi
}

show_status() {
    echo "📊 FSBook Services Status:"
    docker-compose ps
    echo ""
    echo "🌐 Access Points:"
    echo "- Guacamole Web Interface: http://localhost:8080/guacamole"
    echo "- Admin Username: guacadmin"
    echo "- Admin Password: guacadmin"
}

show_logs() {
    if [ -z "$1" ]; then
        echo "📝 Showing logs for all services..."
        docker-compose logs --tail=50 -f
    else
        echo "📝 Showing logs for service: $1"
        docker-compose logs --tail=50 -f "$1"
    fi
}

add_developer() {
    if [ $# -lt 2 ]; then
        echo "❌ Usage: $0 add-dev <developer_name> <rdp_port> [vnc_port]"
        echo "Example: $0 add-dev alice 3393"
        exit 1
    fi
    
    echo "👤 Adding developer: $1 on port $2"
    ./add-developer.sh "$1" "$2" "$3"
    
    echo ""
    echo "🚀 To start the developer container, run:"
    echo "   $0 start dev-$1"
}

remove_developer() {
    if [ -z "$1" ]; then
        echo "❌ Usage: $0 remove-dev <developer_name>"
        exit 1
    fi
    
    echo "⚠️  Removing developer container: $1"
    echo "This will stop and remove the container but keep the data volumes."
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker-compose stop "dev-$1"
        docker-compose rm -f "dev-$1"
        echo "✅ Developer container removed: $1"
        echo "💾 Data volumes preserved: dev-$1-home, dev-$1-workspace"
    else
        echo "❌ Operation cancelled"
    fi
}

list_developers() {
    echo "👥 FSBook Developer Containers:"
    docker-compose ps | grep "fsbook-dev-" | while read line; do
        container_name=$(echo "$line" | awk '{print $1}')
        status=$(echo "$line" | awk '{print $2}')
        ports=$(echo "$line" | awk '{print $6}')
        dev_name=$(echo "$container_name" | sed 's/fsbook-dev-//')
        echo "  📦 $dev_name: $status ($ports)"
    done
}

backup_data() {
    echo "💾 Creating backup of FSBook developer data..."
    timestamp=$(date +%Y%m%d_%H%M%S)
    backup_dir="./backups/fsbook_backup_$timestamp"
    mkdir -p "$backup_dir"
    
    # Backup docker volumes
    docker run --rm -v fsbook_guacamole-db-data:/source -v $(pwd)/$backup_dir:/backup alpine tar czf /backup/database.tar.gz -C /source .
    
    # List all developer volumes and backup them
    docker volume ls | grep "fsbook_dev-" | while read line; do
        volume_name=$(echo "$line" | awk '{print $2}')
        echo "Backing up volume: $volume_name"
        docker run --rm -v "$volume_name":/source -v $(pwd)/$backup_dir:/backup alpine tar czf "/backup/$volume_name.tar.gz" -C /source .
    done
    
    echo "✅ Backup completed: $backup_dir"
}

update_images() {
    echo "🔄 Updating FSBook container images..."
    docker-compose pull
    docker build --no-cache -t fsbook/ubuntu-rdp:latest ./ubuntu-rdp/
    echo "✅ Images updated. Restart containers to use new images."
}

clean_system() {
    echo "🧹 Cleaning up unused Docker resources..."
    docker system prune -f
    docker volume prune -f
    echo "✅ Cleanup completed"
}

reset_system() {
    echo "⚠️  WARNING: This will completely reset the FSBook system!"
    echo "All containers, volumes, and data will be destroyed."
    read -p "Are you absolutely sure? Type 'RESET' to confirm: " confirm
    
    if [ "$confirm" = "RESET" ]; then
        echo "🔥 Resetting FSBook system..."
        docker-compose down -v
        docker system prune -af
        docker volume prune -f
        rm -f docker-compose.override.yml
        echo "✅ System reset completed"
    else
        echo "❌ Reset cancelled"
    fi
}

# Main command processing
case "$1" in
    setup)
        setup_system
        ;;
    start)
        start_services "$2"
        ;;
    stop)
        stop_services "$2"
        ;;
    restart)
        restart_services "$2"
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    add-dev)
        add_developer "$2" "$3" "$4"
        ;;
    remove-dev)
        remove_developer "$2"
        ;;
    list-devs)
        list_developers
        ;;
    backup)
        backup_data
        ;;
    update)
        update_images
        ;;
    clean)
        clean_system
        ;;
    reset)
        reset_system
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac 