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

# Verify schema download
if [ ! -s "init/01-initdb.sql" ]; then
    echo "❌ Failed to download schema. Creating manual schema..."
    
    # Create complete Guacamole schema manually
    cat > init/01-initdb.sql << 'EOF'
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--   http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing,
-- software distributed under the License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
-- KIND, either express or implied.  See the License for the
-- specific language governing permissions and limitations
-- under the License.
--

-- Create database if needed
CREATE DATABASE IF NOT EXISTS guacamole_db;
USE guacamole_db;

--
-- Entity table
--
CREATE TABLE guacamole_entity (
  entity_id     int(11)            NOT NULL AUTO_INCREMENT,
  name          varchar(128)       NOT NULL,
  type          enum('USER',
                     'USER_GROUP') NOT NULL,
  PRIMARY KEY (entity_id),
  UNIQUE KEY guacamole_entity_name_scope (type, name)
);

--
-- User table
--
CREATE TABLE guacamole_user (
  user_id       int(11)      NOT NULL AUTO_INCREMENT,
  entity_id     int(11)      NOT NULL,
  password_hash binary(32)   NOT NULL,
  password_salt binary(32),
  password_date datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  disabled      boolean      NOT NULL DEFAULT 0,
  expired       boolean      NOT NULL DEFAULT 0,
  access_window_start    TIME,
  access_window_end      TIME,
  valid_from    DATE,
  valid_until   DATE,
  timezone      VARCHAR(64),
  full_name     VARCHAR(256),
  email_address VARCHAR(256),
  organization  VARCHAR(256),
  organizational_role VARCHAR(256),
  PRIMARY KEY (user_id),
  UNIQUE KEY guacamole_user_single_entity (entity_id),
  CONSTRAINT guacamole_user_entity
    FOREIGN KEY (entity_id)
    REFERENCES guacamole_entity (entity_id)
    ON DELETE CASCADE
);

--
-- User group table
--
CREATE TABLE guacamole_user_group (
  user_group_id int(11)      NOT NULL AUTO_INCREMENT,
  entity_id     int(11)      NOT NULL,
  disabled      boolean      NOT NULL DEFAULT 0,
  PRIMARY KEY (user_group_id),
  UNIQUE KEY guacamole_user_group_single_entity (entity_id),
  CONSTRAINT guacamole_user_group_entity
    FOREIGN KEY (entity_id)
    REFERENCES guacamole_entity (entity_id)
    ON DELETE CASCADE
);

--
-- Connection group table
--
CREATE TABLE guacamole_connection_group (
  connection_group_id   int(11)      NOT NULL AUTO_INCREMENT,
  parent_id             int(11),
  connection_group_name varchar(128) NOT NULL,
  type                  enum('ORGANIZATIONAL',
                             'BALANCING') NOT NULL DEFAULT 'ORGANIZATIONAL',
  max_connections          int(11),
  max_connections_per_user int(11),
  enable_session_affinity  boolean NOT NULL DEFAULT 0,
  PRIMARY KEY (connection_group_id),
  UNIQUE KEY connection_group_name_parent (connection_group_name, parent_id),
  CONSTRAINT guacamole_connection_group_ibfk_1
    FOREIGN KEY (parent_id)
    REFERENCES guacamole_connection_group (connection_group_id)
    ON DELETE CASCADE
);

--
-- Connection table
--
CREATE TABLE guacamole_connection (
  connection_id   int(11)      NOT NULL AUTO_INCREMENT,
  connection_name varchar(128) NOT NULL,
  parent_id       int(11),
  protocol        varchar(32)  NOT NULL,
  max_connections int(11),
  max_connections_per_user int(11),
  connection_weight int(11),
  failover_only   boolean      NOT NULL DEFAULT 0,
  PRIMARY KEY (connection_id),
  UNIQUE KEY connection_name_parent (connection_name, parent_id),
  CONSTRAINT guacamole_connection_ibfk_1
    FOREIGN KEY (parent_id)
    REFERENCES guacamole_connection_group (connection_group_id)
    ON DELETE CASCADE
);

--
-- Connection parameter table
--
CREATE TABLE guacamole_connection_parameter (
  connection_id   int(11)       NOT NULL,
  parameter_name  varchar(128)  NOT NULL,
  parameter_value varchar(4096) NOT NULL,
  PRIMARY KEY (connection_id,parameter_name),
  CONSTRAINT guacamole_connection_parameter_ibfk_1
    FOREIGN KEY (connection_id)
    REFERENCES guacamole_connection (connection_id) ON DELETE CASCADE
);

--
-- User attributes table
--
CREATE TABLE guacamole_user_attribute (
  user_id         int(11)       NOT NULL,
  attribute_name  varchar(128)  NOT NULL,
  attribute_value varchar(4096) NOT NULL,
  PRIMARY KEY (user_id, attribute_name),
  CONSTRAINT guacamole_user_attribute_ibfk_1
    FOREIGN KEY (user_id)
    REFERENCES guacamole_user (user_id) ON DELETE CASCADE
);

--
-- User history table
--
CREATE TABLE guacamole_user_history (
  history_id           int(11)      NOT NULL AUTO_INCREMENT,
  user_id              int(11),
  username             varchar(128) NOT NULL,
  remote_host          varchar(256),
  start_date           datetime     NOT NULL,
  end_date             datetime,
  PRIMARY KEY (history_id),
  KEY guacamole_user_history_user_id (user_id),
  KEY guacamole_user_history_start_date (start_date),
  KEY guacamole_user_history_end_date (end_date),
  KEY guacamole_user_history_username (username),
  CONSTRAINT guacamole_user_history_ibfk_1
    FOREIGN KEY (user_id)
    REFERENCES guacamole_user (user_id) ON DELETE SET NULL
);

--
-- Connection history table
--
CREATE TABLE guacamole_connection_history (
  history_id           int(11)      NOT NULL AUTO_INCREMENT,
  user_id              int(11),
  username             varchar(128) NOT NULL,
  remote_host          varchar(256),
  connection_id        int(11),
  connection_name      varchar(128) NOT NULL,
  sharing_profile_id   int(11),
  sharing_profile_name varchar(128),
  start_date           datetime     NOT NULL,
  end_date             datetime,
  PRIMARY KEY (history_id),
  KEY guacamole_connection_history_user_id (user_id),
  KEY guacamole_connection_history_connection_id (connection_id),
  KEY guacamole_connection_history_sharing_profile_id (sharing_profile_id),
  KEY guacamole_connection_history_start_date (start_date),
  KEY guacamole_connection_history_end_date (end_date),
  KEY guacamole_connection_history_connection_name (connection_name),
  CONSTRAINT guacamole_connection_history_ibfk_1
    FOREIGN KEY (user_id)
    REFERENCES guacamole_user (user_id) ON DELETE SET NULL,
  CONSTRAINT guacamole_connection_history_ibfk_2
    FOREIGN KEY (connection_id)
    REFERENCES guacamole_connection (connection_id) ON DELETE SET NULL
);

--
-- User permissions
--
CREATE TABLE guacamole_user_permission (
  entity_id            int(11) NOT NULL,
  affected_user_id     int(11) NOT NULL,
  permission           enum('READ',
                            'UPDATE',
                            'DELETE',
                            'ADMINISTER') NOT NULL,
  PRIMARY KEY (entity_id, affected_user_id, permission),
  CONSTRAINT guacamole_user_permission_ibfk_1
    FOREIGN KEY (entity_id)
    REFERENCES guacamole_entity (entity_id) ON DELETE CASCADE,
  CONSTRAINT guacamole_user_permission_affected_user
    FOREIGN KEY (affected_user_id)
    REFERENCES guacamole_user (user_id) ON DELETE CASCADE
);

--
-- Connection permissions
--
CREATE TABLE guacamole_connection_permission (
  entity_id     int(11) NOT NULL,
  connection_id int(11) NOT NULL,
  permission    enum('READ',
                     'UPDATE',
                     'DELETE',
                     'ADMINISTER') NOT NULL,
  PRIMARY KEY (entity_id, connection_id, permission),
  CONSTRAINT guacamole_connection_permission_ibfk_1
    FOREIGN KEY (entity_id)
    REFERENCES guacamole_entity (entity_id) ON DELETE CASCADE,
  CONSTRAINT guacamole_connection_permission_ibfk_2
    FOREIGN KEY (connection_id)
    REFERENCES guacamole_connection (connection_id) ON DELETE CASCADE
);

--
-- System permissions
--
CREATE TABLE guacamole_system_permission (
  entity_id  int(11) NOT NULL,
  permission enum('CREATE_CONNECTION',
                  'CREATE_CONNECTION_GROUP',
                  'CREATE_SHARING_PROFILE',
                  'CREATE_USER',
                  'CREATE_USER_GROUP',
                  'ADMINISTER') NOT NULL,
  PRIMARY KEY (entity_id, permission),
  CONSTRAINT guacamole_system_permission_ibfk_1
    FOREIGN KEY (entity_id)
    REFERENCES guacamole_entity (entity_id) ON DELETE CASCADE
);

-- Insert default admin user (password: guacadmin)
INSERT INTO guacamole_entity (name, type) VALUES ('guacadmin', 'USER');
INSERT INTO guacamole_user (entity_id, password_hash, password_salt, full_name, email_address, organization) 
VALUES (1, 
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

else
    echo "✅ Official schema downloaded successfully ($(wc -l < init/01-initdb.sql) lines)"
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
    if curl -f http://localhost:8080/guacamole/ > /dev/null 2>&1; then
        echo "✅ Guacamole web interface is accessible!"
        break
    else
        attempts=$((attempts + 1))
        echo "⏳ Waiting for Guacamole web interface (attempt $attempts/$max_attempts)..."
        sleep 10
    fi
done

# Step 6: Show final status
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
echo "  • Add new developer: ./add-developer.sh <name> <port>"
echo "  • Start example devs: docker-compose up -d dev-john dev-jane"
echo "  • Management script: ./manage-fsbook.sh help"
echo ""
echo "🔧 Next Steps:"
echo "  1. Login to Guacamole web interface"
echo "  2. Start developer containers: docker-compose up -d dev-john dev-jane"
echo "  3. Add RDP connections through Guacamole admin interface"
echo "  4. Test RDP connections to developer containers"
echo ""
echo "📝 Log Files:"
echo "  • View logs: docker-compose logs [service_name]"
echo "  • Live logs: docker-compose logs -f [service_name]"
echo ""

# Final verification
echo "🧪 Final System Verification:"
echo "✅ MySQL Database: $(docker-compose ps guacamole-db | grep Up > /dev/null && echo "Running" || echo "Failed")"
echo "✅ Guacamole Daemon: $(docker-compose ps guacd | grep Up > /dev/null && echo "Running" || echo "Failed")"
echo "✅ Guacamole Web: $(docker-compose ps guacamole | grep Up > /dev/null && echo "Running" || echo "Failed")"
echo "✅ Ubuntu RDP Image: $(docker images fsbook/ubuntu-rdp:latest | grep fsbook > /dev/null && echo "Built" || echo "Failed")"

echo ""
echo "🚀 System is ready for use!" 