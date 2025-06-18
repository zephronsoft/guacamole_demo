Perfect! Here are the step-by-step setup commands for your FSBook Guacamole developer environment:

## 🚀 Step-by-Step Setup Commands

### Step 1: Make Scripts Executable
```bash
chmod +x setup-guacamole.sh add-developer.sh manage-fsbook.sh
```

### Step 2: Initial System Setup
```bash
# This will download Guacamole schema, build Ubuntu RDP image, and start core services
./setup-guacamole.sh
```

### Step 3: Verify Services Are Running
```bash
# Check status of all containers
docker-compose ps

# Or use the management script
./manage-fsbook.sh status
```

### Step 4: Access Guacamole Web Interface
- **URL**: http://localhost:8080/guacamole
- **Username**: `guacadmin`  
- **Password**: `guacadmin`

### Step 5: Start Example Developer Containers
```bash
# Start John's container (RDP on port 3391)
docker-compose up -d dev-john

# Start Jane's container (RDP on port 3392)  
docker-compose up -d dev-jane

# Or start both at once
docker-compose up -d dev-john dev-jane
```

### Step 6: Add New Developers (Example)
```bash
# Add a developer named "alice" on RDP port 3393
./add-developer.sh alice 3393

# Start Alice's container
docker-compose up -d dev-alice

# Or use the management script
./manage-fsbook.sh add-dev bob 3394
./manage-fsbook.sh start dev-bob
```

## 🔧 Management Commands

### Check System Status
```bash
./manage-fsbook.sh status
```

### View Logs
```bash
# All services logs
./manage-fsbook.sh logs

# Specific service logs
./manage-fsbook.sh logs guacamole
./manage-fsbook.sh logs dev-john
```

### List All Developers
```bash
./manage-fsbook.sh list-devs
```

### Stop/Start Services
```bash
# Stop all services
./manage-fsbook.sh stop

# Start all services
./manage-fsbook.sh start

# Restart specific service
./manage-fsbook.sh restart dev-john
```

## 🖥️ Connection Methods

### Method 1: Through Guacamole (Recommended)
1. Go to http://localhost:8080/guacamole
2. Login with `guacadmin` / `guacadmin`
3. Click on the developer connection you want to access

### Method 2: Direct RDP Connection
```bash
# Connect directly via RDP client to:
# John: localhost:3391 (username: john, password: developer123)
# Jane: localhost:3392 (username: jane, password: developer123)
# Alice: localhost:3393 (username: alice, password: developer123)
```

## 🛠️ Troubleshooting Commands

### If Services Don't Start
```bash
# Check detailed logs
docker-compose logs guacamole-db
docker-compose logs guacd
docker-compose logs guacamole

# Restart services
docker-compose restart
```

### If Database Issues
```bash
# Reset database (WARNING: loses data)
docker-compose down
docker volume rm guacamole_guacamole-db-data
docker-compose up -d guacamole-db
# Wait 30 seconds then start other services
docker-compose up -d guacd guacamole
```

### Complete Reset (if needed)
```bash
# WARNING: This removes all data
./manage-fsbook.sh reset
# Then run setup again
./setup-guacamole.sh
```

## 📋 Quick Reference

| Action | Command |
|--------|---------|
| Setup system | `./setup-guacamole.sh` |
| Add developer | `./add-developer.sh <name> <port>` |
| Start all | `./manage-fsbook.sh start` |
| Check status | `./manage-fsbook.sh status` |
| View logs | `./manage-fsbook.sh logs` |
| Access web UI | http://localhost:8080/guacamole |

## 🎯 Expected Results

After setup completion, you should have:
- ✅ Guacamole web interface running on port 8080
- ✅ MySQL database with proper schema
- ✅ Two example developer containers (john, jane) ready to start
- ✅ All scripts executable and ready to use
- ✅ Persistent storage volumes created for each developer

Would you like me to explain any of these steps in more detail or help you troubleshoot if you encounter any issues?