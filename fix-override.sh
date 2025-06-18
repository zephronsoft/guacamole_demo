#!/bin/bash

echo "🔧 Fixing docker-compose.override.yml and organizing connections..."

# Remove the problematic override file
rm -f docker-compose.override.yml

# Recreate birru with proper environment folder
echo "🔄 Re-adding birru to dev environment..."
./add-developer-rdp-only.sh birru 3393 birru birru123 dev

# Add the connection to database if it's running
if docker-compose ps guacamole-db | grep -q "Up"; then
    echo "🔗 Adding birru connection to Guacamole..."
    docker-compose exec -T guacamole-db mysql -u guacamole_user -pguacamole_password << EOF
USE guacamole_db;

-- Create dev environment folder if it doesn't exist
INSERT IGNORE INTO guacamole_connection_group (connection_group_name, type) 
VALUES ('dev', 'ORGANIZATIONAL');

-- Update existing john and jane connections to be in dev folder
UPDATE guacamole_connection 
SET parent_id = (SELECT connection_group_id FROM guacamole_connection_group WHERE connection_group_name = 'dev' LIMIT 1),
    connection_name = 'john'
WHERE connection_name LIKE '%john%';

UPDATE guacamole_connection 
SET parent_id = (SELECT connection_group_id FROM guacamole_connection_group WHERE connection_group_name = 'dev' LIMIT 1),
    connection_name = 'jane'
WHERE connection_name LIKE '%jane%';

-- Grant admin permissions to dev folder
SET @dev_group_id = (SELECT connection_group_id FROM guacamole_connection_group WHERE connection_group_name = 'dev' LIMIT 1);

INSERT IGNORE INTO guacamole_connection_group_permission (entity_id, connection_group_id, permission)
SELECT guacamole_entity.entity_id, @dev_group_id, permission
FROM guacamole_entity
CROSS JOIN (
    SELECT 'READ' AS permission
    UNION SELECT 'UPDATE' AS permission
    UNION SELECT 'DELETE' AS permission
    UNION SELECT 'ADMINISTER' AS permission
) permissions
WHERE guacamole_entity.name = 'guacadmin' AND guacamole_entity.type = 'USER';
EOF

    echo "✅ Connections organized into folders!"
else
    echo "⚠️ Database not running. Start services first: docker-compose up -d"
fi

echo ""
echo "📁 Environment Folders Structure:"
echo "  📂 dev/"
echo "    🖥️ john"
echo "    🖥️ jane"
echo "    🖥️ birru"
echo ""
echo "🚀 To start birru container:"
echo "   docker-compose up -d dev-birru"
echo ""
echo "🌐 Guacamole Access:"
echo "   URL: http://localhost:8080/guacamole"
echo "   Login: guacadmin / guacadmin"
echo "   You'll see organized folders: dev, qa, prod" 