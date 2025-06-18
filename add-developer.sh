#!/bin/bash

# FSBook Developer Container Setup Script
# Usage: ./add-developer.sh <developer_name> <rdp_port> [vnc_port]

if [ $# -lt 2 ]; then
    echo "Usage: $0 <developer_name> <rdp_port> [vnc_port]"
    echo "Example: $0 alice 3393 5903"
    exit 1
fi

DEVELOPER_NAME=$1
RDP_PORT=$2
VNC_PORT=${3:-$((5900 + ${RDP_PORT} - 3390))}  # Auto-calculate VNC port if not provided

echo "Creating developer container for: $DEVELOPER_NAME"
echo "RDP Port: $RDP_PORT"
echo "VNC Port: $VNC_PORT"

# Create docker-compose override for the new developer
cat >> docker-compose.override.yml << EOF

  # Developer: $DEVELOPER_NAME
  dev-$DEVELOPER_NAME:
    image: fsbook/ubuntu-rdp:latest
    container_name: fsbook-dev-$DEVELOPER_NAME
    environment:
      - DEVELOPER_NAME=$DEVELOPER_NAME
      - USER_PASSWORD=developer123
      - VNC_PASSWORD=vnc123
    ports:
      - "$RDP_PORT:3389"  # RDP port mapping
      - "$VNC_PORT:5900"  # VNC port mapping
    volumes:
      - dev-$DEVELOPER_NAME-home:/home/$DEVELOPER_NAME
      - dev-$DEVELOPER_NAME-workspace:/workspace
    networks:
      - fsbook-guacamole-network
    restart: unless-stopped
EOF

# Add volume definitions if they don't exist
if ! grep -q "dev-$DEVELOPER_NAME-home:" docker-compose.override.yml; then
    echo "  dev-$DEVELOPER_NAME-home:" >> docker-compose.override.yml
    echo "  dev-$DEVELOPER_NAME-workspace:" >> docker-compose.override.yml
fi

echo "Developer container configuration added to docker-compose.override.yml"
echo ""
echo "To start the container, run:"
echo "docker-compose up -d dev-$DEVELOPER_NAME"
echo ""
echo "RDP Connection Details:"
echo "Host: localhost"
echo "Port: $RDP_PORT"
echo "Username: $DEVELOPER_NAME"
echo "Password: developer123"
echo ""
echo "VNC Connection Details (backup):"
echo "Host: localhost"
echo "Port: $VNC_PORT"
echo "Password: vnc123" 