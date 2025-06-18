#!/bin/bash

# FSBook RDP-Only Developer Container Setup Script
# Usage: ./add-developer-rdp-only.sh <developer_name> <rdp_port> <username> <password> [environment]

if [ $# -lt 4 ]; then
    echo "Usage: $0 <developer_name> <rdp_port> <username> <password> [environment]"
    echo "Example: $0 birru 3393 birru birru123 dev"
    echo ""
    echo "Parameters:"
    echo "  developer_name: Container name (e.g., birru)"
    echo "  rdp_port:      RDP port number (e.g., 3393)"
    echo "  username:      Login username for RDP (e.g., birru)"
    echo "  password:      Login password for RDP (e.g., birru123)"
    echo "  environment:   Environment folder (dev, qa, prod) - defaults to 'dev'"
    exit 1
fi

DEVELOPER_NAME=$1
RDP_PORT=$2
USERNAME=$3
PASSWORD=$4
ENVIRONMENT=${5:-dev}  # Default to 'dev' if not specified

echo "Creating RDP-only developer container for: $DEVELOPER_NAME"
echo "RDP Port: $RDP_PORT"
echo "Username: $USERNAME"
echo "Password: [HIDDEN]"
echo "Environment: $ENVIRONMENT"

# Create or append to docker-compose override file
if [ ! -f "docker-compose.override.yml" ]; then
    cat > docker-compose.override.yml << EOF
services:
EOF
fi

# Add the new developer service (RDP only)
cat >> docker-compose.override.yml << EOF

  # Developer: $DEVELOPER_NAME (RDP Only) - Environment: $ENVIRONMENT
  dev-$DEVELOPER_NAME:
    image: fsbook/ubuntu-rdp:latest
    container_name: fsbook-dev-$DEVELOPER_NAME
    environment:
      - DEVELOPER_NAME=$USERNAME
      - USER_PASSWORD=$PASSWORD
      # Performance optimizations
      - DISPLAY=:0
      - XRDP_OPTIMIZE=true
    ports:
      - "$RDP_PORT:3389"  # RDP port only
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

# Add volume definitions properly (fix the validation error)
if ! grep -q "^volumes:" docker-compose.override.yml; then
    echo "" >> docker-compose.override.yml
    echo "volumes:" >> docker-compose.override.yml
fi

# Check if volumes already exist before adding
if ! grep -q "dev-$DEVELOPER_NAME-home:" docker-compose.override.yml; then
    echo "  dev-$DEVELOPER_NAME-home:" >> docker-compose.override.yml
fi

if ! grep -q "dev-$DEVELOPER_NAME-workspace:" docker-compose.override.yml; then
    echo "  dev-$DEVELOPER_NAME-workspace:" >> docker-compose.override.yml
fi

# Create Guacamole connection with environment folder organization
echo "🔗 Creating Guacamole RDP connection in $ENVIRONMENT folder..."
cat > /tmp/add-connection-$DEVELOPER_NAME.sql << EOF
USE guacamole_db;

-- Create or get environment connection group (dev, qa, prod)
INSERT IGNORE INTO guacamole_connection_group (connection_group_name, type) 
VALUES ('$ENVIRONMENT', 'ORGANIZATIONAL');

SET @group_id = (SELECT connection_group_id FROM guacamole_connection_group WHERE connection_group_name = '$ENVIRONMENT' LIMIT 1);

-- Create RDP-only connection for $DEVELOPER_NAME in $ENVIRONMENT folder
INSERT INTO guacamole_connection (connection_name, parent_id, protocol) 
VALUES ('$DEVELOPER_NAME', @group_id, 'rdp');

SET @connection_id = LAST_INSERT_ID();

-- Add optimized RDP-only connection parameters
INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value) VALUES 
(@connection_id, 'hostname', 'fsbook-dev-$DEVELOPER_NAME'),
(@connection_id, 'port', '3389'),
(@connection_id, 'username', '$USERNAME'),
(@connection_id, 'password', '$PASSWORD'),
(@connection_id, 'security', 'any'),
(@connection_id, 'ignore-cert', 'true'),
(@connection_id, 'enable-drive', 'true'),
(@connection_id, 'create-drive-path', 'true'),
-- Performance optimizations for RDP
(@connection_id, 'color-depth', '16'),
(@connection_id, 'disable-bitmap-caching', 'false'),
(@connection_id, 'disable-offscreen-caching', 'false'),
(@connection_id, 'disable-glyph-caching', 'false'),
(@connection_id, 'enable-wallpaper', 'false'),
(@connection_id, 'enable-theming', 'false'),
(@connection_id, 'enable-font-smoothing', 'false'),
(@connection_id, 'enable-full-window-drag', 'false'),
(@connection_id, 'enable-desktop-composition', 'false'),
(@connection_id, 'enable-menu-animations', 'false'),
(@connection_id, 'resize-method', 'reconnect');

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

-- Grant admin permissions to the connection group
INSERT IGNORE INTO guacamole_connection_group_permission (entity_id, connection_group_id, permission)
SELECT guacamole_entity.entity_id, @group_id, permission
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
    echo "✅ Guacamole RDP connection created in '$ENVIRONMENT' folder"
else
    echo "⚠️ Database not running. Connection will be created when you start the database."
    mv /tmp/add-connection-$DEVELOPER_NAME.sql init/04-connection-$DEVELOPER_NAME.sql
fi

echo "RDP-only developer container configuration added!"
echo ""
echo "🚀 To start the container, run:"
echo "   docker-compose up -d dev-$DEVELOPER_NAME"
echo ""
echo "🔗 RDP Connection Details:"
echo "   Host: localhost"
echo "   Port: $RDP_PORT"
echo "   Username: $USERNAME"
echo "   Password: $PASSWORD"
echo ""
echo "🌐 Guacamole Web Access:"
echo "   URL: http://localhost:8080/guacamole"
echo "   Folder: $ENVIRONMENT"
echo "   Connection: '$DEVELOPER_NAME'"
echo ""
echo "✅ Features:"
echo "   • RDP-only access (no VNC)"
echo "   • Organized in '$ENVIRONMENT' folder"
echo "   • Optimized for speed"
echo "   • XFCE4 desktop environment"
echo "   • Workspace folder on desktop"
echo "   • Development tools included" 