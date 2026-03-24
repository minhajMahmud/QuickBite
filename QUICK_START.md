# 🚀 QuickBite PostgreSQL + pgAdmin4 - Quick Start Guide

## ⚡ Get Started in 3 Steps

### Step 1: Start Docker (30 seconds)
```bash
cd e:\quickbite
docker-compose up -d
```

### Step 2: Wait for Containers
```bash
docker-compose ps
# Wait until both containers show "Up"
```

### Step 3: Open pgAdmin4
Go to: **http://localhost:5050**

---

## 🔐 Login to pgAdmin4

| Field | Value |
|-------|-------|
| **Email** | admin@quickbite.com |
| **Password** | admin_password_2024 |

---

## 📊 Access Your Database

After login, you'll see:

1. **Left Sidebar** → Click **Servers**
2. **QuickBite PostgreSQL** server appears (pre-configured!)
3. Expand to see **Databases → quickbite → Schemas → public → Tables**

---

## 💾 Database Connection Details

```
Host:     localhost
Port:     5432
Database: quickbite
User:     quickbite_user
Password: quickbite_password_2024
```

---

## 🔄 Common Tasks

### View a Table
1. **Servers** → **QuickBite PostgreSQL** → **Databases** → **quickbite** → **Schemas** → **public** → **Tables**
2. Right-click any table → **View/Edit Data** → **All Rows**

### Run a SQL Query
1. **Tools** → **Query Tool** (or press Alt+Shift+Q)
2. Write your SQL
3. Press **F5** to execute

### Example Queries
```sql
-- View all restaurants
SELECT * FROM restaurants;

-- View all users
SELECT name, email, total_orders, total_spent FROM users;

-- View recent orders
SELECT o.id, u.name, r.name, o.total_amount, o.order_status 
FROM orders o
JOIN users u ON o.user_id = u.id
JOIN restaurants r ON o.restaurant_id = r.id
ORDER BY o.created_at DESC LIMIT 10;
```

### Create a Backup
1. Right-click **quickbite** database
2. **Backup** → Configure options → **Backup**

### Restore from Backup
1. Right-click **quickbite** database
2. **Restore** → Select your backup file

---

## 📈 Using Helper Script (Windows PowerShell)

```bash
# Start containers
.\docker-helper.ps1 start

# View logs
.\docker-helper.ps1 logs

# Connect to database shell
.\docker-helper.ps1 shell

# Create backup
.\docker-helper.ps1 backup

# Check database size
.\docker-helper.ps1 size

# Show statistics
.\docker-helper.ps1 stats
```

---

## ⚙️ File Locations

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Main Docker configuration |
| `database_schema.sql` | Database schema (20 tables) |
| `init-data.sql` | Sample test data |
| `pgadmin_servers.json` | pgAdmin server config |
| `docker-helper.ps1` | Windows PowerShell helper script |

---

## 🆘 Troubleshooting

### Containers not starting?
```bash
docker-compose logs
```

### Port 5050 already in use?
Edit `docker-compose.yml` and change:
```yaml
ports:
  - "5051:80"  # Instead of 5050
```
Then access: http://localhost:5051

### Can't connect to database?
```bash
# Wait 30 seconds and try again
docker-compose ps

# If unhealthy, restart:
docker-compose restart postgres
```

### Forgot pgAdmin password?
```bash
docker-compose down
# Edit docker-compose.yml, change PGADMIN_DEFAULT_PASSWORD
docker-compose up -d
```

---

## 📚 What's Included

✅ **PostgreSQL 16** - Latest stable database  
✅ **pgAdmin4** - Professional database management UI  
✅ **20 Database Tables** - Complete QuickBite schema  
✅ **Sample Data** - 4 restaurants, 3 users, multiple orders  
✅ **Persistent Storage** - Data survives container restarts  
✅ **Auto-initialization** - Schema and data loaded automatically  
✅ **Health Checks** - Automatic service verification  
✅ **Network Isolation** - Private network between containers  

---

## 🎯 Next Steps

1. ✅ Start containers: `docker-compose up -d`
2. ✅ Open pgAdmin: http://localhost:5050
3. ✅ Explore tables and data
4. ✅ Run sample queries
5. ✅ Connect your app: `postgresql://quickbite_user:quickbite_password_2024@localhost:5432/quickbite`

---

## 📞 Quick Commands

```bash
# Start
docker-compose up -d

# Stop
docker-compose stop

# Restart
docker-compose restart

# View status
docker-compose ps

# View logs
docker-compose logs -f

# Remove everything
docker-compose down -v

# Access database shell
docker-compose exec postgres psql -U quickbite_user -d quickbite

# Create backup
docker-compose exec -T postgres pg_dump -U quickbite_user -d quickbite > backup.sql
```

---

**You're all set! 🎉**

Open [http://localhost:5050](http://localhost:5050) and start managing your database!

*Last Updated: March 24, 2026*
