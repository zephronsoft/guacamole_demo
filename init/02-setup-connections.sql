-- Setup initial RDP connections for FSBook developers
USE guacamole_db;

-- Wait for tables to be created by the main schema
-- Insert RDP connections for example developers

-- Connection for John
INSERT INTO guacamole_connection (connection_name, protocol) 
VALUES ('FSBook Dev - John', 'rdp');

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

-- Connection for Jane
INSERT INTO guacamole_connection (connection_name, protocol) 
VALUES ('FSBook Dev - Jane', 'rdp');

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