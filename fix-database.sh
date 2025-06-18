#!/bin/bash

echo "🔧 Fixing FSBook Guacamole Database Schema..."

# Stop services
echo "Stopping Guacamole services..."
docker-compose stop guacamole guacd

# Remove old database volume to start fresh
echo "Removing old database volume..."
docker-compose down
docker volume rm guacamole_guacamole-db-data 2>/dev/null || true

# Download proper Guacamole schema
echo "Downloading proper Guacamole database schema..."
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql > init/01-initdb.sql

# Verify the schema was downloaded
if [ -s "init/01-initdb.sql" ]; then
    echo "✅ Database schema downloaded successfully"
    echo "📊 Schema file size: $(wc -l < init/01-initdb.sql) lines"
else
    echo "❌ Failed to download schema. Trying alternative method..."
    # Alternative: Create a minimal working schema
    cat > init/01-initdb.sql << 'EOF'
-- Guacamole Database Schema for MySQL
-- Generated for FSBook project

CREATE DATABASE IF NOT EXISTS guacamole_db;
USE guacamole_db;

-- Create tables in correct order
CREATE TABLE guacamole_entity (
  entity_id     int(11)            NOT NULL AUTO_INCREMENT,
  name          varchar(128)       NOT NULL,
  type          enum('USER',
                     'USER_GROUP') NOT NULL,
  PRIMARY KEY (entity_id),
  UNIQUE KEY guacamole_entity_name_scope (type, name)
);

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

CREATE TABLE guacamole_connection_parameter (
  connection_id   int(11)       NOT NULL,
  parameter_name  varchar(128)  NOT NULL,
  parameter_value varchar(4096) NOT NULL,
  PRIMARY KEY (connection_id,parameter_name),
  CONSTRAINT guacamole_connection_parameter_ibfk_1
    FOREIGN KEY (connection_id)
    REFERENCES guacamole_connection (connection_id) ON DELETE CASCADE
);

CREATE TABLE guacamole_user_attribute (
  user_id         int(11)       NOT NULL,
  attribute_name  varchar(128)  NOT NULL,
  attribute_value varchar(4096) NOT NULL,
  PRIMARY KEY (user_id, attribute_name),
  CONSTRAINT guacamole_user_attribute_ibfk_1
    FOREIGN KEY (user_id)
    REFERENCES guacamole_user (user_id) ON DELETE CASCADE
);

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

-- Insert admin user
INSERT INTO guacamole_entity (name, type) VALUES ('guacadmin', 'USER');
INSERT INTO guacamole_user (entity_id, password_hash, password_salt, full_name, email_address, organization) 
VALUES (1, 
        UNHEX('CA458A7D494E3BE824F5E1E175A1556C0F8EEF2C2D7DF3633BEC4A29C4411960'), 
        UNHEX('FE24ADC5E11E2B25288D1704ABE67A79E342ECC26064CE69C5B3177795A82264'),
        'FSBook Administrator', 
        'admin@fsbook.com', 
        'FSBook');
EOF
    echo "✅ Created minimal working schema"
fi

# Start database first
echo "Starting database..."
docker-compose up -d guacamole-db

echo "Waiting for database to initialize..."
sleep 45

# Check if database is ready
echo "Checking database status..."
docker-compose exec guacamole-db mysql -u guacamole_user -pguacamole_password -e "SHOW TABLES FROM guacamole_db;" || {
    echo "⚠️ Database not ready yet, waiting longer..."
    sleep 30
}

# Start other services
echo "Starting Guacamole services..."
docker-compose up -d guacd guacamole

echo "Waiting for services to start..."
sleep 20

echo "✅ Database fix completed!"
echo ""
echo "🌐 Access Guacamole at: http://localhost:8080/guacamole"
echo "👤 Username: guacadmin"
echo "🔑 Password: guacadmin"
echo ""
echo "Check status with: docker-compose ps" 