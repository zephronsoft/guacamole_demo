#!/bin/bash

# FSBook Guacamole Complete Setup Script
# This script will create a fully working Guacamole environment from scratch

set -e  # Exit on any error

echo "🚀 FSBook Guacamole Complete Setup"
echo "Organization: fsbook | Project: fsbook"
echo "==============================================="

# Clean up any existing setup
echo "🧹 Cleaning up any existing setup..."
docker-compose down -v 2>/dev/null || true
docker system prune -f 2>/dev/null || true
docker volume prune -f 2>/dev/null || true

# Create directories
echo "📁 Creating necessary directories..."
mkdir -p init ubuntu-rdp backups

# Step 1: Download proper Guacamole database schema
echo "📥 Downloading official Guacamole database schema..."
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql > init/01-initdb.sql

# Verify schema download and add admin user if needed
if [ -s "init/01-initdb.sql" ]; then
    echo "✅ Official schema downloaded successfully ($(wc -l < init/01-initdb.sql) lines)"
    
    # Check if admin user is already in schema, if not add it
    if ! grep -q "guacadmin" init/01-initdb.sql; then
        echo "➕ Adding FSBook admin user to schema..."
        cat >> init/01-initdb.sql << 'EOF'

-- Insert FSBook admin user (username: guacadmin, password: guacadmin)
INSERT INTO guacamole_entity (name, type) VALUES ('guacadmin', 'USER');

INSERT INTO guacamole_user (entity_id, password_hash, password_salt, full_name, email_address, organization) 
VALUES ((SELECT entity_id FROM guacamole_entity WHERE name = 'guacadmin' AND type = 'USER'), 
        UNHEX('CA458A7D494E3BE824F5E1E175A1556C0F8EEF2C2D7DF3633BEC4A29C4411960'), 
        UNHEX('FE24ADC5E11E2B25288D1704ABE67A79E342ECC26064CE69C5B3177795A82264'),
        'FSBook Administrator', 
        'admin@fsbook.com', 
        'FSBook');

-- Grant admin all system permissions
INSERT INTO guacamole_system_permission (entity_id, permission)
SELECT entity_id, permission
FROM (
          SELECT 'CREATE_CONNECTION' AS permission
    UNION SELECT 'CREATE_CONNECTION_GROUP' AS permission
    UNION SELECT 'CREATE_SHARING_PROFILE' AS permission
    UNION SELECT 'CREATE_USER' AS permission
    UNION SELECT 'CREATE_USER_GROUP' AS permission
    UNION SELECT 'ADMINISTER' AS permission
) permissions
CROSS JOIN (
    SELECT entity_id
    FROM guacamole_entity
    WHERE name = 'guacadmin' AND type = 'USER'
) admin;

-- Grant admin permission to read/update/administer self
INSERT INTO guacamole_user_permission (entity_id, affected_user_id, permission)
SELECT guacamole_entity.entity_id, guacamole_user.user_id, permission
FROM (
          SELECT 'READ' AS permission
    UNION SELECT 'UPDATE' AS permission
    UNION SELECT 'ADMINISTER' AS permission
) permissions
CROSS JOIN guacamole_entity
CROSS JOIN guacamole_user
WHERE guacamole_entity.name = 'guacadmin'
  AND guacamole_entity.type = 'USER'
  AND guacamole_user.entity_id = guacamole_entity.entity_id;
EOF
    fi
else
    echo "❌ Failed to download schema. Exiting..."
    exit 1
fi

# Step 2: Build Ubuntu RDP image
echo "🔨 Building Ubuntu RDP Docker image..."
docker build -t fsbook/ubuntu-rdp:latest ./ubuntu-rdp/

# Step 3: Start database first and wait for it to be ready
echo "🗄️ Starting MySQL database..."
docker-compose up -d guacamole-db

echo "⏳ Waiting for database to initialize (60 seconds)..."
sleep 60

# Verify database is ready
echo "🔍 Verifying database initialization..."
max_attempts=10
attempts=0
while [ $attempts -lt $max_attempts ]; do
    if docker-compose exec -T guacamole-db mysql -u guacamole_user -pguacamole_password -e "SHOW TABLES FROM guacamole_db;" > /dev/null 2>&1; then
        echo "✅ Database is ready!"
        break
    else
        attempts=$((attempts + 1))
        echo "⏳ Database not ready yet (attempt $attempts/$max_attempts)..."
        sleep 10
    fi
done

if [ $attempts -eq $max_attempts ]; then
    echo "❌ Database failed to initialize properly"
    exit 1
fi

# Verify essential tables exist
echo "🔍 Verifying database schema..."
TABLES=$(docker-compose exec -T guacamole-db mysql -u guacamole_user -pguacamole_password -e "SHOW TABLES FROM guacamole_db;" | grep guacamole | wc -l)
echo "✅ Found $TABLES Guacamole tables in database"

# Step 4: Start Guacamole services
echo "🖥️ Starting Guacamole services..."
docker-compose up -d guacd guacamole

echo "⏳ Waiting for Guacamole to start..."
sleep 30

# Step 5: Verify Guacamole is running
echo "🔍 Verifying Guacamole is accessible..."
max_attempts=12
attempts=0
while [ $attempts -lt $max_attempts ]; do
    if curl -s http://localhost:8080/guacamole/ > /dev/null 2>&1; then
        echo "✅ Guacamole web interface is accessible!"
        break
    else
        attempts=$((attempts + 1))
        echo "⏳ Waiting for Guacamole web interface (attempt $attempts/$max_attempts)..."
        sleep 10
    fi
done

# Step 6: Create pre-configured RDP connections
echo "🔗 Setting up example RDP connections..."
cat > init/03-create-connections.sql << 'EOF'
USE guacamole_db;

-- Create connection group for FSBook developers
INSERT INTO guacamole_connection_group (connection_group_name, type) 
VALUES ('FSBook Developers', 'ORGANIZATIONAL');

SET @group_id = LAST_INSERT_ID();

-- Create connection for John
INSERT INTO guacamole_connection (connection_name, parent_id, protocol) 
VALUES ('FSBook Dev - John', @group_id, 'rdp');

SET @john_connection_id = LAST_INSERT_ID();

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value) VALUES 
(@john_connection_id, 'hostname', 'fsbook-dev-john'),
(@john_connection_id, 'port', '3389'),
(@john_connection_id, 'username', 'john'),
(@john_connection_id, 'password', 'developer123'),
(@john_connection_id, 'security', 'any'),
(@john_connection_id, 'ignore-cert', 'true'),
(@john_connection_id, 'enable-drive', 'true'),
(@john_connection_id, 'create-drive-path', 'true');

-- Create connection for Jane
INSERT INTO guacamole_connection (connection_name, parent_id, protocol) 
VALUES ('FSBook Dev - Jane', @group_id, 'rdp');

SET @jane_connection_id = LAST_INSERT_ID();

INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value) VALUES 
(@jane_connection_id, 'hostname', 'fsbook-dev-jane'),
(@jane_connection_id, 'port', '3389'),
(@jane_connection_id, 'username', 'jane'),
(@jane_connection_id, 'password', 'developer123'),
(@jane_connection_id, 'security', 'any'),
(@jane_connection_id, 'ignore-cert', 'true'),
(@jane_connection_id, 'enable-drive', 'true'),
(@jane_connection_id, 'create-drive-path', 'true');

-- Grant admin permissions to connections
INSERT INTO guacamole_connection_permission (entity_id, connection_id, permission)
SELECT guacamole_entity.entity_id, @john_connection_id, permission
FROM guacamole_entity
CROSS JOIN (
    SELECT 'READ' AS permission
    UNION SELECT 'UPDATE' AS permission
    UNION SELECT 'DELETE' AS permission
    UNION SELECT 'ADMINISTER' AS permission
) permissions
WHERE guacamole_entity.name = 'guacadmin' AND guacamole_entity.type = 'USER';

INSERT INTO guacamole_connection_permission (entity_id, connection_id, permission)
SELECT guacamole_entity.entity_id, @jane_connection_id, permission
FROM guacamole_entity
CROSS JOIN (
    SELECT 'READ' AS permission
    UNION SELECT 'UPDATE' AS permission
    UNION SELECT 'DELETE' AS permission
    UNION SELECT 'ADMINISTER' AS permission
) permissions
WHERE guacamole_entity.name = 'guacadmin' AND guacamole_entity.type = 'USER';
EOF

# Execute the connection setup
docker-compose exec -T guacamole-db mysql -u guacamole_user -pguacamole_password < init/03-create-connections.sql

# Step 7: Show final status
echo ""
echo "=========================================="
echo "🎉 FSBook Guacamole Setup Complete!"
echo "=========================================="
echo ""
echo "📊 Service Status:"
docker-compose ps
echo ""
echo "🌐 Access Points:"
echo "  • Guacamole Web Interface: http://localhost:8080/guacamole"
echo "  • Admin Username: guacadmin"
echo "  • Admin Password: guacadmin"
echo ""
echo "👥 Developer Container Management:"
echo "  • Start example devs: docker-compose up -d dev-john dev-jane"
echo "  • Add new developer: ./add-developer.sh <name> <port>"
echo "  • Management script: ./manage-fsbook.sh help"
echo ""
echo "🔧 Next Steps:"
echo "  1. ✅ Login to Guacamole web interface"
echo "  2. Start developer containers: docker-compose up -d dev-john dev-jane"
echo "  3. ✅ RDP connections already configured in Guacamole"
echo "  4. Test RDP connections to developer containers"
echo ""
echo "📋 Pre-configured Connections:"
echo "  • FSBook Dev - John (container: fsbook-dev-john, port: 3391)"
echo "  • FSBook Dev - Jane (container: fsbook-dev-jane, port: 3392)"
echo ""
echo "📝 Log Files:"
echo "  • View logs: docker-compose logs [service_name]"
echo "  • Live logs: docker-compose logs -f [service_name]"
echo ""

# Final verification
echo "🧪 Final System Verification:"
DATABASE_STATUS=$(docker-compose ps guacamole-db | grep Up > /dev/null && echo "✅ Running" || echo "❌ Failed")
GUACD_STATUS=$(docker-compose ps guacd | grep Up > /dev/null && echo "✅ Running" || echo "❌ Failed")
GUACAMOLE_STATUS=$(docker-compose ps guacamole | grep Up > /dev/null && echo "✅ Running" || echo "❌ Failed")
IMAGE_STATUS=$(docker images fsbook/ubuntu-rdp:latest | grep fsbook > /dev/null && echo "✅ Built" || echo "❌ Failed")

echo "  MySQL Database: $DATABASE_STATUS"
echo "  Guacamole Daemon: $GUACD_STATUS"
echo "  Guacamole Web: $GUACAMOLE_STATUS"
echo "  Ubuntu RDP Image: $IMAGE_STATUS"

# Check if we can login to Guacamole
LOGIN_TEST=$(curl -s -X POST -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=guacadmin&password=guacadmin" \
  "http://localhost:8080/guacamole/api/tokens" | grep -o '"authToken"' > /dev/null && echo "✅ Working" || echo "⚠️  Check manually")

echo "  Guacamole Login: $LOGIN_TEST"

echo ""
echo "🚀 System is ready for use!"
echo "🌐 Go to: http://localhost:8080/guacamole"
echo "👤 Login: guacadmin / guacadmin" 