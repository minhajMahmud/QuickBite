# 🐳 QuickBite Docker & Database Setup

Complete Docker setup for PostgreSQL and pgAdmin4 management console.

---

## 📦 What You Get

- **PostgreSQL 16 Alpine** - Lightweight, production-ready database
- **pgAdmin4** - Web-based database management interface
- **Automatic Schema Setup** - 20 tables pre-created
- **Sample Data** - Test data loaded automatically
- **Persistent Storage** - Data survives container restarts
- **Health Checks** - Automatic service verification
- **Helper Scripts** - Easy management commands

---

## ✅ System Requirements

- Docker Desktop for Windows, Mac, or Linux
- 2GB RAM minimum (4GB+ recommended)
- 500MB free disk space
- Ports 5432 and 5050 available

### Check Prerequisites
```bash
docker --version    # Should be 20.10+
docker-compose --version    # Should be 2.0+
```

---

## 🚀 Quick Start (3 Steps)

### 1️⃣ Start Containers
```bash
cd e:\quickbite
docker-compose up -d
```

### 2️⃣ Wait for Startup
```bash
docker-compose ps
# All services should show "Up"
```

### 3️⃣ Open pgAdmin4
Visit: **http://localhost:5050**

**Login:**
- Email: `admin@quickbite.com`
- Password: `admin_password_2024`

---

## 📂 Files Created

```
quickbite/
├── docker-compose.yml          # Main docker configuration
├── database_schema.sql         # 20 database tables
├── init-data.sql              # Sample data (4 restaurants, 3 users)
├── pgadmin_servers.json       # pgAdmin config (pre-configured)
├── .env.example               # Environment variables template
├── docker-helper.ps1          # PowerShell helper script
├── docker-manager.bat         # Windows batch helper
├── DOCKER_SETUP.md           # Detailed setup guide
├── QUICK_START.md            # Quick reference
└── DATABASE_SCHEMA.md        # Schema documentation
```

---

## 🔐 Credentials

### PostgreSQL
```
Host:     localhost
Port:     5432
Database: quickbite
User:     quickbite_user
Password: quickbite_password_2024
```

### pgAdmin4
```
URL:      http://localhost:5050
Email:    admin@quickbite.com
Password: admin_password_2024
```

---

## 🎮 Usage

### Using Helper Script (PowerShell)
```bash
# Windows PowerShell
.\docker-helper.ps1 start          # Start containers
.\docker-helper.ps1 logs           # View logs
.\docker-helper.ps1 shell          # Connect to database
.\docker-helper.ps1 backup         # Create backup
.\docker-helper.ps1 stats          # Show statistics
.\docker-helper.ps1 reset          # Reset database
.\docker-helper.ps1 help           # Show all commands
```

### Using Helper Script (Batch)
```bash
# Windows Command Prompt
docker-manager.bat start
docker-manager.bat logs
docker-manager.bat shell
docker-manager.bat backup
docker-manager.bat status
docker-manager.bat help
```

### Using Docker Compose Directly
```bash
# Start in background
docker-compose up -d

# Stop containers
docker-compose stop

# Restart containers
docker-compose restart

# View status
docker-compose ps

# View logs
docker-compose logs -f

# Connect to database shell
docker-compose exec postgres psql -U quickbite_user -d quickbite

# Create backup
docker-compose exec -T postgres pg_dump -U quickbite_user -d quickbite > backup.sql

# Remove everything (including data!)
docker-compose down -v
```

---

## 📊 Using pgAdmin4

### Access Database
1. Open http://localhost:5050
2. Login with credentials above
3. Expand **Servers** → **QuickBite PostgreSQL** in left sidebar

### View Tables
1. Navigate to **Databases** → **quickbite** → **Schemas** → **public** → **Tables**
2. Right-click table → **View/Edit Data** → **All Rows**

### Run Query
1. **Tools** → **Query Tool** (Alt+Shift+Q)
2. Write SQL and press **F5** to execute

### Create Backup
1. Right-click **quickbite** database
2. **Backup** → Configure options → **Backup**
3. Download file automatically

### Restore Database
1. Right-click **quickbite** database
2. **Restore** → Select backup file

---

## 📁 Database Contents

### Tables (20 Total)
- **Users**: User accounts and profiles
- **Restaurants**: Restaurant information
- **Food Items**: Menu items
- **Orders**: Customer orders
- **Delivery**: Delivery agents and tracking
- **Ratings**: User reviews and ratings
- **Promotions**: Coupons and discounts
- **Admin**: Admin users and activity logs
- **Notifications**: System notifications
- **Analytics**: Revenue statistics

### Sample Data
- **3 Users** with addresses and order history
- **4 Restaurants** (Pizza, Burgers, Pasta, Fresh Salads)
- **11 Food Items** across categories
- **4 Orders** with status history
- **3 Delivery Agents**
- **3 Active Coupons**

---

## 🔧 Configuration

### Environment Variables
Create `.env` file from template:
```bash
cp .env.example .env
```

Edit for your needs:
```env
DB_USER=your_username
DB_PASSWORD=your_password
PGADMIN_EMAIL=your_email@example.com
PGADMIN_PASSWORD=your_password
```

### Custom Ports
Edit `docker-compose.yml`:
```yaml
postgres:
  ports:
    - "5433:5432"  # Change 5432 to 5433

pgadmin:
  ports:
    - "5051:80"    # Change 5050 to 5051
```

### Add More Sample Data
Edit `init-data.sql` and add INSERT statements

---

## 🔄 Common Operations

### View Database Size
```bash
docker-compose exec -T postgres psql -U quickbite_user -d quickbite -c \
  "SELECT pg_size_pretty(pg_database_size('quickbite'));"
```

### Check Active Connections
```bash
docker-compose exec -T postgres psql -U quickbite_user -d quickbite -c \
  "SELECT * FROM pg_stat_activity WHERE datname = 'quickbite';"
```

### List All Tables
```bash
docker-compose exec postgres psql -U quickbite_user -d quickbite -c "\dt"
```

### Export Table to CSV
```sql
\copy (SELECT * FROM restaurants) TO 'restaurants.csv' WITH CSV HEADER;
```

### Clear All Data (Keep Schema)
```sql
TRUNCATE TABLE order_items CASCADE;
TRUNCATE TABLE orders CASCADE;
TRUNCATE TABLE coupon_usage CASCADE;
TRUNCATE TABLE user_favorites CASCADE;
-- ... continue for other tables
```

---

## ⚠️ Troubleshooting

### Containers Won't Start
```bash
# Check logs
docker-compose logs

# Verify Docker is running
docker ps

# Try restarting Docker Desktop
```

### Port Already in Use
Old containers might be occupying ports:
```bash
# Stop and remove all containers
docker-compose down

# Or change port in docker-compose.yml
```

### Database Not Connecting in pgAdmin
- Wait 30 seconds for PostgreSQL to start
- Refresh browser page
- Check container health: `docker-compose ps`
- View logs: `docker-compose logs postgres`

### "Cannot find docker-compose"
Install Docker Compose separately or upgrade Docker Desktop

### Data Not Persisting
Ensure you're not using `-v` flag when stopping:
```bash
docker-compose stop      # Keeps data
docker-compose down -v   # Deletes data
```

### Backup File is Empty
- Ensure `-T` flag is used: `docker-compose exec -T postgres ...`
- Check file permissions
- Try with absolute path

---

## 🚀 Production Deployment

Current setup is for **development only**. For production:

### Security
- ✅ Use strong passwords (32+ characters)
- ✅ Enable SSL/TLS for connections
- ✅ Set up firewall rules
- ✅ Use environment variables for secrets
- ✅ Enable database backups

### High Availability
- ✅ Use PostgreSQL replication
- ✅ Set up load balancing
- ✅ Configure automatic failover
- ✅ Monitor disk space

### Performance
- ✅ Allocate sufficient resources
- ✅ Enable connection pooling
- ✅ Optimize frequently-used queries
- ✅ Set up monitoring and alerts

### Example Production docker-compose.yml
```yaml
version: '3.8'
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - /backup:/backup  # External backup location
    ports:
      - "${DB_PORT}:5432"
    restart: always
    networks:
      - quickbite_network
```

---

## 📊 Monitoring & Maintenance

### Scheduled Backups
```bash
# Add to Windows Task Scheduler
docker-compose exec -T postgres pg_dump -U quickbite_user -d quickbite > backup_$(date +\%Y\%m\%d).sql
```

### Monitor Disk Usage
```bash
docker system df              # Check Docker disk usage
docker volume ls              # List all volumes
docker volume inspect [ID]    # Check volume size
```

### Clean Up Old Resources
```bash
docker system prune           # Remove unused containers
docker volume prune           # Remove unused volumes
```

---

## 📚 References

- [Docker Documentation](https://docs.docker.com/)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [pgAdmin Docs](https://www.pgadmin.org/docs/)
- [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md) - Full schema documentation
- [DOCKER_SETUP.md](./DOCKER_SETUP.md) - Detailed setup guide

---

## 🆘 Need Help?

1. Check [Troubleshooting](#-troubleshooting) section
2. View logs: `docker-compose logs`
3. Check status: `docker-compose ps`
4. Verify network: `docker network ls`
5. Restart fresh: `docker-compose down -v && docker-compose up -d`

---

## 📝 Notes

- First start takes 30-60 seconds while PostgreSQL initializes
- Sample data is automatically loaded on first run
- Data persists between container restarts
- Use `docker-compose down -v` to completely reset
- pgAdmin configuration is automatically saved

---

## ✨ What's Next?

1. ✅ Start containers: `docker-compose up -d`
2. ✅ Open pgAdmin: http://localhost:5050
3. ✅ Login and explore tables
4. ✅ Run sample queries
5. ✅ Create backups
6. ✅ Connect your application
7. ✅ Monitor performance
8. ✅ Set up automated backups

---

**Ready? Start now:**
```bash
cd e:\quickbite
docker-compose up -d
# Then visit http://localhost:5050
```

*Last Updated: March 24, 2026*
*Docker Setup Version 1.0*
