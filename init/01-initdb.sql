-- This file will be replaced by the actual Guacamole schema
-- The setup script will download the proper schema from the Guacamole container
-- and replace this file with the complete database initialization script. CREATE TABLE IF NOT EXISTS `guacamole_connection_parameter` (-- Initialize Guacamole database
-- This script will be automatically executed when the MySQL container starts

USE guacamole_db;

-- Create tables for Guacamole
CREATE TABLE IF NOT EXISTS `guacamole_connection` (
  `connection_id`   int(11)      NOT NULL AUTO_INCREMENT,
  `connection_name` varchar(128) NOT NULL,
  `parent_id`       int(11)      DEFAULT NULL,
  `protocol`        varchar(32)  NOT NULL,
  `max_connections` int(11)      DEFAULT NULL,
  `max_connections_per_user` int(11) DEFAULT NULL,
  `connection_weight` int(11)    DEFAULT NULL,
  `failover_only`   boolean      NOT NULL DEFAULT 0,
  PRIMARY KEY (`connection_id`),
  UNIQUE KEY `connection_name_parent` (`connection_name`, `parent_id`),
  KEY `guacamole_connection_ibfk_1` (`parent_id`)
);

CREATE TABLE IF NOT EXISTS `guacamole_connection_parameter` (
  `connection_id`   int(11)       NOT NULL,
  `parameter_name`  varchar(128)  NOT NULL,
  `parameter_value` varchar(4096) NOT NULL,
  PRIMARY KEY (`connection_id`,`parameter_name`),
  KEY `guacamole_connection_parameter_ibfk_1` (`connection_id`)
);

CREATE TABLE IF NOT EXISTS `guacamole_user` (
  `user_id`       int(11)      NOT NULL AUTO_INCREMENT,
  `username`      varchar(128) NOT NULL,
  `password_hash` binary(32)   NOT NULL,
  `password_salt` binary(32),
  `password_date` datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `disabled`      boolean      NOT NULL DEFAULT 0,
  `expired`       boolean      NOT NULL DEFAULT 0,
  `access_window_start`    TIME,
  `access_window_end`      TIME,
  `valid_from`    DATE,
  `valid_until`   DATE,
  `timezone`      VARCHAR(64),
  `full_name`     VARCHAR(256),
  `email_address` VARCHAR(256),
  `organization`  VARCHAR(256),
  `organizational_role` VARCHAR(256),
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `username` (`username`)
);

-- Insert admin user (password: admin)
INSERT INTO guacamole_user (username, password_hash, password_salt, full_name, email_address, organization) 
VALUES ('guacadmin', 
        UNHEX('CA458A7D494E3BE824F5E1E175A1556C0F8EEF2C2D7DF3633BEC4A29C4411960'), 
        UNHEX('FE24ADC5E11E2B25288D1704ABE67A79E342ECC26064CE69C5B3177795A82264'),
        'Administrator', 
        'admin@fsbook.com', 
        'FSBook');

-- Add more tables as needed for full Guacamole functionality
-- (This is a simplified version - full schema would be larger)

->

-- This file will be replaced by the actual Guacamole schema
-- The setup script will download the proper schema from the Guacamole container
-- and replace this file with the complete database initialization script.