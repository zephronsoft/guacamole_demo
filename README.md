# FSBook Guacamole Developer Environment

A Docker Compose setup for Apache Guacamole with multiple Ubuntu developer containers supporting RDP connections.

## 🏢 Organization: FSBook
## 📋 Project: FSBook Developer Infrastructure

## Features

- **Apache Guacamole** web-based remote desktop gateway
- **Multiple Developer Containers** with Ubuntu + XFCE desktop environment
- **RDP Support** for remote desktop access
- **VNC Backup** for alternative connection method
- **Persistent Storage** for each developer's home directory and workspace
- **Easy Developer Management** with automated scripts
- **Customizable Ports** for each developer container

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   Web Browser   │───▶│   Guacamole      │───▶│  Developer          │
│   (Port 8080)   │    │   Web Interface  │    │  Containers         │
└─────────────────┘    └──────────────────┘    │  (RDP: 3391+)       │
                              │                 │  (VNC: 5901+)       │
                              ▼                 └─────────────────────┘
                       ┌──────────────────┐    
                       │     MySQL        │    
                       │    Database      │    
                       └──────────────────┘    
```

## Quick Start

### 1. Initial Setup

```bash
# Make setup script executable
chmod +x setup-guacamole.sh add-developer.sh

# Run the setup (this will download Guacamole schema and build images)
./setup-guacamole.sh
```

### 2. Access Guacamole Web Interface

- **URL**: http://localhost:8080/guacamole
- **Username**: `guacadmin`
- **Password**: `guacadmin`

### 3. Start Example Developer Containers

```bash
# Start individual developer containers
docker-compose up -d dev-john    # RDP: localhost:3391
docker-compose up -d dev-jane    # RDP: localhost:3392

# Or start all developer containers
docker-compose up -d dev-john dev-jane
```

## Adding New Developers

### Method 1: Using the Script (Recommended)

```bash
# Add a new developer with automatic port assignment
./add-developer.sh alice 3393

# Add a developer with custom RDP and VNC ports  
./add-developer.sh bob 3394 5904

# Start the new developer container
docker-compose up -d dev-alice
```

### Method 2: Manual Docker Compose Configuration

Add to `docker-compose.override.yml`:

```yaml
services:
  dev-newdeveloper:
    image: fsbook/ubuntu-rdp:latest
    container_name: fsbook-dev-newdeveloper
    environment:
      - DEVELOPER_NAME=newdeveloper
      - USER_PASSWORD=developer123
      - VNC_PASSWORD=vnc123
    ports:
      - "3395:3389"  # RDP port
      - "5905:5900"  # VNC port
    volumes:
      - dev-newdeveloper-home:/home/newdeveloper
      - dev-newdeveloper-workspace:/workspace
    networks:
      - fsbook-guacamole-network
    restart: unless-stopped

volumes:
  dev-newdeveloper-home:
  dev-newdeveloper-workspace:
```

## Connection Methods

### Option 1: Through Guacamole Web Interface (Recommended)
1. Open http://localhost:8080/guacamole
2. Login with admin credentials
3. Select the developer connection from the list
4. Connect through your web browser

### Option 2: Direct RDP Connection
- **Host**: `localhost`
- **Port**: `339X` (where X is the developer number)
- **Username**: `[developer_name]`
- **Password**: `developer123`

### Option 3: Direct VNC Connection (Backup)
- **Host**: `localhost`
- **Port**: `590X` (where X is the developer number)
- **Password**: `vnc123`

## Default Port Assignments

| Developer | Container Name    | RDP Port | VNC Port |
|-----------|------------------|----------|----------|
| john      | fsbook-dev-john  | 3391     | 5901     |
| jane      | fsbook-dev-jane  | 3392     | 5902     |

## Directory Structure

```
fsbook-guacamole/
├── docker-compose.yml          # Main Docker Compose configuration
├── docker-compose.override.yml # Additional developer containers
├── setup-guacamole.sh         # Initial setup script
├── add-developer.sh           # Script to add new developers
├── ubuntu-rdp/                # Ubuntu RDP container configuration
│   ├── Dockerfile
│   └── start.sh
├── init/                      # Database initialization scripts
│   ├── 01-initdb.sql
│   └── 02-setup-connections.sql
└── README.md                  # This file
```

## Persistent Storage

Each developer gets:
- **Home Directory**: `/home/[developer_name]` - Personal files and settings
- **Workspace**: `/workspace` - Shared development workspace

Data persists across container restarts and updates.

## Installed Software

Each developer container includes:
- Ubuntu 22.04 LTS
- XFCE4 Desktop Environment
- Firefox Web Browser
- Visual Studio Code
- Git
- Python3 + pip
- Node.js + npm
- Build tools (gcc, make, etc.)
- Text editors (vim, nano)

## Management Commands

```bash
# View all containers
docker-compose ps

# View logs
docker-compose logs guacamole
docker-compose logs dev-john

# Stop specific developer
docker-compose stop dev-john

# Remove developer container (keeps data)
docker-compose rm dev-john

# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Update developer container
docker-compose pull fsbook/ubuntu-rdp:latest
docker-compose up -d --force-recreate dev-john
```

## Security Considerations

⚠️ **Important Security Notes**:

1. **Change Default Passwords**: Update default passwords in production
2. **Network Security**: Restrict access to RDP/VNC ports
3. **SSL/TLS**: Configure HTTPS for Guacamole in production
4. **Firewall**: Use proper firewall rules for port access
5. **User Management**: Create individual Guacamole users for each developer

## Troubleshooting

### Container Won't Start
```bash
# Check logs
docker-compose logs [service_name]

# Rebuild container
docker-compose build --no-cache ubuntu-rdp
```

### RDP Connection Issues
```bash
# Check if container is running
docker-compose ps

# Check port mapping
docker port fsbook-dev-john

# Test connection
telnet localhost 3391
```

### Database Issues
```bash
# Reset database
docker-compose down
docker volume rm guacamole_guacamole-db-data
docker-compose up -d
```

## Customization

### Environment Variables

Key environment variables for developer containers:
- `DEVELOPER_NAME`: Username for the developer
- `USER_PASSWORD`: Password for RDP/VNC access
- `VNC_PASSWORD`: VNC-specific password

### Adding Software

Modify `ubuntu-rdp/Dockerfile` to add additional software packages.

## Support

For FSBook internal support, contact the DevOps team or create an issue in the internal repository.

---

**FSBook Developer Infrastructure Team** 