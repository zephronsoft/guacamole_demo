#!/bin/bash

# FSBook Guacamole Setup Script
echo "=== FSBook Guacamole Setup ==="
echo "Organization: fsbook"
echo "Project: fsbook"

# Create necessary directories
mkdir -p init ubuntu-rdp

# Download Guacamole database schema if not exists
if [ ! -f "init/01-initdb.sql" ]; then
    echo "Downloading Guacamole database schema..."
    # You can customize this to download the actual Guacamole schema
    docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql > init/01-initdb.sql
fi

# Build the Ubuntu RDP image
echo "Building Ubuntu RDP image..."
docker build -t fsbook/ubuntu-rdp:latest ./ubuntu-rdp/

# Start the core services (database, guacd, guacamole)
echo "Starting core Guacamole services..."
docker-compose up -d guacamole-db guacd guacamole

# Wait for database to be ready
echo "Waiting for database to initialize..."
sleep 30

# Check if services are running
echo "Checking service status..."
docker-compose ps

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Guacamole Web Interface: http://localhost:8080/guacamole"
echo "Default admin credentials:"
echo "Username: guacadmin"
echo "Password: guacadmin"
echo ""
echo "To add a new developer, run:"
echo "./add-developer.sh <developer_name> <rdp_port>"
echo ""
echo "Example developer containers are already configured:"
echo "- John: RDP port 3391, VNC port 5901"
echo "- Jane: RDP port 3392, VNC port 5902"
echo ""
echo "To start example developers:"
echo "docker-compose up -d dev-john dev-jane" 