#!/bin/bash

# FSBook Enhanced Developer Container Setup Script
# Usage: ./add-developer-advanced.sh <developer_name> <rdp_port> <username> <password> [vnc_port]

if [ $# -lt 4 ]; then
    echo "Usage: $0 <developer_name> <rdp_port> <username> <password> [vnc_port]"
    echo "Example: $0 alice 3393 alice mypassword123 5903"
    echo ""
    echo "Parameters:"
    echo "  developer_name: Container name (e.g., alice)"
    echo "  rdp_port:      RDP port number (e.g., 3393)"
    echo "  username:      Login username for RDP (e.g., alice)"
    echo "  password:      Login password for RDP (e.g., mypassword123)"
    echo "  vnc_port:      Optional VNC port (auto-calculated if not provided)"
    exit 1
fi

DEVELOPER_NAME=$1
RDP_PORT=$2
USERNAME=$3
PASSWORD=$4
VNC_PORT=${5:-$((5900 + ${RDP_PORT} - 3390))}  # Auto-calculate VNC port if not provided

echo "Creating developer container for: $DEVELOPER_NAME"
echo "RDP Port: $RDP_PORT"
echo "VNC Port: $VNC_PORT"
echo "Username: $USERNAME"
echo "Password: [HIDDEN]"

# Create or append to docker-compose override file
if [ ! -f "docker-compose.override.yml" ]; then
    cat > docker-compose.override.yml << EOF
version: '3.8'
services:
EOF
fi

# Add the new developer service
cat >> docker-compose.override.yml << EOF

  # Developer: $DEVELOPER_NAME
  dev-$DEVELOPER_NAME:
    image: fsbook/ubuntu-rdp:latest
    container_name: fsbook-dev-$DEVELOPER_NAME
    environment:
      - DEVELOPER_NAME=$USERNAME
      - USER_PASSWORD=$PASSWORD
      - VNC_PASSWORD=vnc123
      # Performance optimizations
      - DISPLAY=:0
      - XRDP_OPTIMIZE=true
    ports:
      - "$RDP_PORT:3389"  # RDP port mapping
      - "$VNC_PORT:5900"  # VNC port mapping
    volumes:
      - dev-$DEVELOPER_NAME-home:/home/$USERNAME
      - dev-$DEVELOPER_NAME-workspace:/workspace
    networks:
      - fsbook-guacamole-network
    restart: unless-stopped
    # Performance optimizations
    shm_size: '1gb'
    cpu_count: 2
    mem_limit: 2g
EOF

# Add volume definitions
if ! grep -q "volumes:" docker-compose.override.yml; then
    echo "" >> docker-compose.override.yml
    echo "volumes:" >> docker-compose.override.yml
fi

echo "  dev-$DEVELOPER_NAME-home:" >> docker-compose.override.yml
echo "  dev-$DEVELOPER_NAME-workspace:" >> docker-compose.override.yml

# Create Guacamole connection automatically
echo "🔗 Creating Guacamole RDP connection..."
cat > /tmp/add-connection-$DEVELOPER_NAME.sql << EOF
USE guacamole_db;

-- Create connection for $DEVELOPER_NAME
INSERT INTO guacamole_connection (connection_name, protocol) 
VALUES ('FSBook Dev - $DEVELOPER_NAME', 'rdp');

SET @connection_id = LAST_INSERT_ID();

-- Add optimized connection parameters
INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value) VALUES 
(@connection_id, 'hostname', 'fsbook-dev-$DEVELOPER_NAME'),
(@connection_id, 'port', '3389'),
(@connection_id, 'username', '$USERNAME'),
(@connection_id, 'password', '$PASSWORD'),
(@connection_id, 'security', 'any'),
(@connection_id, 'ignore-cert', 'true'),
(@connection_id, 'enable-drive', 'true'),
(@connection_id, 'create-drive-path', 'true'),
-- Performance optimizations
(@connection_id, 'color-depth', '16'),
(@connection_id, 'disable-bitmap-caching', 'false'),
(@connection_id, 'disable-offscreen-caching', 'false'),
(@connection_id, 'disable-glyph-caching', 'false'),
(@connection_id, 'preconnection-id', ''),
(@connection_id, 'enable-wallpaper', 'false'),
(@connection_id, 'enable-theming', 'false'),
(@connection_id, 'enable-font-smoothing', 'false'),
(@connection_id, 'enable-full-window-drag', 'false'),
(@connection_id, 'enable-desktop-composition', 'false'),
(@connection_id, 'enable-menu-animations', 'false');

-- Grant admin permissions to the connection
INSERT INTO guacamole_connection_permission (entity_id, connection_id, permission)
SELECT guacamole_entity.entity_id, @connection_id, permission
FROM guacamole_entity
CROSS JOIN (
    SELECT 'READ' AS permission
    UNION SELECT 'UPDATE' AS permission
    UNION SELECT 'DELETE' AS permission
    UNION SELECT 'ADMINISTER' AS permission
) permissions
WHERE guacamole_entity.name = 'guacadmin' AND guacamole_entity.type = 'USER';
EOF

# Execute the connection creation if database is running
if docker-compose ps guacamole-db | grep -q "Up"; then
    docker-compose exec -T guacamole-db mysql -u guacamole_user -pguacamole_password < /tmp/add-connection-$DEVELOPER_NAME.sql
    rm /tmp/add-connection-$DEVELOPER_NAME.sql
    echo "✅ Guacamole connection created automatically"
else
    echo "⚠️ Database not running. Connection will be created when you start the database."
    mv /tmp/add-connection-$DEVELOPER_NAME.sql init/04-connection-$DEVELOPER_NAME.sql
fi

echo "Developer container configuration added to docker-compose.override.yml"
echo ""
echo "🚀 To start the container, run:"
echo "docker-compose up -d dev-$DEVELOPER_NAME"
echo ""
echo "🔗 Connection Details:"
echo "RDP Connection:"
echo "  Host: localhost"
echo "  Port: $RDP_PORT"
echo "  Username: $USERNAME"
echo "  Password: $PASSWORD"
echo ""
echo "VNC Connection (backup):"
echo "  Host: localhost"
echo "  Port: $VNC_PORT"
echo "  Password: vnc123"
echo ""
echo "🌐 Guacamole Web Access:"
echo "  URL: http://localhost:8080/guacamole"
echo "  Connection: 'FSBook Dev - $DEVELOPER_NAME'" 