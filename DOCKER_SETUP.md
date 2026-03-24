# QuickBite Docker Setup Guide

## 🐳 Docker Setup with PostgreSQL & pgAdmin4

This guide will help you set up PostgreSQL and pgAdmin4 using Docker to manage your QuickBite database.

---

## 📋 Prerequisites

Before you begin, make sure you have:
- **Docker Desktop** installed ([Download here](https://www.docker.com/products/docker-desktop))
- **Docker Compose** (included with Docker Desktop)
- Windows PowerShell or Command Prompt

### Verify Docker Installation
```bash
docker --version
docker-compose --version
```

---

## 🚀 Quick Start

### 1. Navigate to Project Directory
```bash
cd e:\quickbite
```

### 2. Start Docker Containers
```bash
docker-compose up -d
```

This command will:
- ✅ Download PostgreSQL 16 Alpine image (if not present)
- ✅ Download pgAdmin4 latest image (if not present)
- ✅ Create PostgreSQL container
- ✅ Create pgAdmin4 container
- ✅ Create network connection between them
- ✅ Create persistent volumes for data
- ✅ Initialize database schema and sample data

### 3. Wait for Services to Start
The PostgreSQL health check takes ~10-30 seconds. Wait for both services to be ready:

```bash
docker-compose ps
```

Expected output:
```
NAME                           STATUS
quickbite_postgres            Up (healthy)
quickbite_pgadmin             Up
```

---

## 🔐 Access Credentials

### PostgreSQL Database
- **Host**: localhost (or 127.0.0.1)
- **Port**: 5432
- **Database**: quickbite
- **Username**: quickbite_user
- **Password**: quickbite_password_2024

### pgAdmin4 Web Interface
- **URL**: http://localhost:5050
- **Email**: admin@quickbite.com
- **Password**: admin_password_2024

---

## 🌐 Accessing pgAdmin4

### Step 1: Open pgAdmin4
1. Open your web browser
2. Navigate to: [http://localhost:5050](http://localhost:5050)
3. Accept any certificate warnings (SSL certificate may not be valid locally)

### Step 2: Login
1. Enter credentials:
   - **Email**: admin@quickbite.com
   - **Password**: admin_password_2024
2. Click "Login"

### Step 3: Access Database Server
The server is pre-configured and should appear automatically:
1. In the left sidebar, click on **Servers**
2. You should see **QuickBite PostgreSQL**
3. Expand it to view databases and tables

---

## 📊 Using pgAdmin4 Features

### Viewing Tables
1. **Servers** → **QuickBite PostgreSQL** → **Databases** → **quickbite** → **Schemas** → **public** → **Tables**
2. Right-click any table and select **View Data** → **All Rows**

### Running Queries
1. Click on the **Query Tool** icon (or right-click database → Query Tool)
2. Write your SQL queries
3. Press **F5** or click **Execute** button
4. View results in the **Data Output** tab

### Example Query
```sql
-- Get all restaurants
SELECT id, name, cuisine, rating, status 
FROM restaurants 
WHERE is_approved = true
ORDER BY rating DESC;

-- Get user orders
SELECT o.id, o.order_status, o.total_amount, o.created_at
FROM orders o
WHERE o.user_id = 'user-1'
ORDER BY o.created_at DESC;
```

### Creating Backups
1. Right-click **quickbite** database
2. Select **Backup**
3. Choose backup options and location
4. Download backup file

### Restoring Data
1. Right-click **quickbite** database
2. Select **Restore**
3. Upload your backup file
4. Click **Restore**

---

## 🛠️ Docker Commands Reference

### View Running Containers
```bash
docker-compose ps
```

### View Container Logs
```bash
# View all logs
docker-compose logs

# View PostgreSQL logs
docker-compose logs postgres

# View pgAdmin logs
docker-compose logs pgadmin

# Follow logs in real-time
docker-compose logs -f
```

### Access PostgreSQL Container CLI
```bash
docker-compose exec postgres psql -U quickbite_user -d quickbite
```

Then you can run SQL commands directly:
```sql
\dt                    -- List all tables
SELECT * FROM users;   -- Query users table
\q                     -- Exit psql
```

### Stop Containers
```bash
docker-compose stop
```

### Start Containers Again
```bash
docker-compose start
```

### Restart Containers
```bash
docker-compose restart
```

### Remove Containers (keeps data)
```bash
docker-compose down
```

### Remove Everything (delete data too)
```bash
docker-compose down -v
```

---

## 📁 File Structure

Your project now contains:

```
quickbite/
├── docker-compose.yml          # Docker configuration
├── database_schema.sql         # Database schema (auto-imported)
├── init-data.sql              # Sample data (auto-imported)
├── pgadmin_servers.json       # pgAdmin server configuration
├── DATABASE_SCHEMA.md         # Schema documentation
├── ER_DIAGRAM.md             # Entity relationships
├── SCHEMA_QUICK_REFERENCE.md # Quick reference guide
└── ... (other project files)
```

### Data Persistence

Docker volumes automatically save your data:
- **postgres_data**: Database files
- **pgadmin_data**: pgAdmin configuration

Your data persists even when containers are stopped/removed (unless you explicitly delete volumes with `-v` flag).

---

## 🔧 Configuration Details

### docker-compose.yml Sections

#### PostgreSQL Service
```yaml
postgres:
  image: postgres:16-alpine
  environment:
    POSTGRES_USER: quickbite_user
    POSTGRES_PASSWORD: quickbite_password_2024
    POSTGRES_DB: quickbite
  volumes:
    - postgres_data:/var/lib/postgresql/data
    - ./database_schema.sql:/docker-entrypoint-initdb.d/01-schema.sql
    - ./init-data.sql:/docker-entrypoint-initdb.d/02-init-data.sql
  ports:
    - "5432:5432"
```

#### pgAdmin Service
```yaml
pgadmin:
  image: dpage/pgadmin4:latest
  environment:
    PGADMIN_DEFAULT_EMAIL: admin@quickbite.com
    PGADMIN_DEFAULT_PASSWORD: admin_password_2024
  volumes:
    - pgadmin_data:/var/lib/pgadmin
    - ./pgadmin_servers.json:/pgadmin4/servers.json
  ports:
    - "5050:80"
  depends_on:
    postgres:
      condition: service_healthy
```

---

## ⚠️ Troubleshooting

### Issue: "docker-compose: command not found"
**Solution**: Update Docker Desktop or install Docker Compose separately
```bash
# Install Docker Compose separately for Windows
# Or use: docker compose (newer versions)
docker compose up -d
```

### Issue: Port 5432 already in use
**Solution**: Change port in docker-compose.yml
```yaml
ports:
  - "5433:5432"  # Change 5432 to 5433
```
Then connect to `localhost:5433`

### Issue: Port 5050 already in use
**Solution**: Change port in docker-compose.yml
```yaml
ports:
  - "5051:80"  # Change 5050 to 5051
```
Then access pgAdmin at `http://localhost:5051`

### Issue: "Cannot connect to database"
**Solution**: Check container health
```bash
docker-compose ps
# If status shows "unhealthy", restart:
docker-compose restart postgres
```

### Issue: Database schema not imported
**Solution**: Files must be in the project root directory
```bash
# Verify files exist:
dir database_schema.sql
dir init-data.sql

# If not, reinitialize:
docker-compose down -v
docker-compose up -d
```

### Issue: pgAdmin can't see PostgreSQL server
**Solution**: The server connection takes time. Wait 30 seconds and refresh the page
```bash
# Check logs:
docker-compose logs postgres
```

### Issue: "Too many connections" error
**Solution**: Increase max connections in docker-compose.yml
```yaml
postgres:
  environment:
    POSTGRES_INITDB_ARGS: "--encoding=UTF8 --max_connections=300"
```

---

## 🔄 Updating Configuration

### Change Database Password
1. Edit `docker-compose.yml`:
```yaml
postgres:
  environment:
    POSTGRES_PASSWORD: your_new_password
```

2. Also update `pgadmin_servers.json`:
```json
"Password": "your_new_password"
```

3. Rebuild containers:
```bash
docker-compose down -v
docker-compose up -d
```

### Add More Sample Data
1. Edit `init-data.sql`
2. Add your SQL INSERT statements
3. Reinitialize:
```bash
docker-compose down -v
docker-compose up -d
```

---

## 📊 Database Monitoring

### Using pgAdmin Monitoring
1. In pgAdmin, right-click **QuickBite PostgreSQL** server
2. Select **Dashboard**
3. View real-time statistics:
   - Active connections
   - Database size
   - Transaction throughput
   - Cache hit ratio

### Monitor from Command Line
```bash
# Connect to database
docker-compose exec postgres psql -U quickbite_user -d quickbite

# Check database size
SELECT datname, pg_size_pretty(pg_database_size(datname)) 
FROM pg_database 
WHERE datname = 'quickbite';

# List all tables with row counts
SELECT schemaname, tablename, 
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) 
FROM pg_tables 
WHERE schemaname != 'pg_catalog' 
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

# Exit
\q
```

---

## 🚀 Production Considerations

### Current Setup (Development)
- ✅ Great for local development
- ✅ Auto-initialization of schema and data
- ✅ Easy to reset and rebuild
- ✅ Perfect for testing

### For Production
- [ ] Use strong, unique passwords
- [ ] Enable SSL/TLS connections
- [ ] Set up automated backups
- [ ] Use environment variables for secrets
- [ ] Configure resource limits
- [ ] Set up log rotation
- [ ] Enable monitoring and alerts
- [ ] Use managed database services (AWS RDS, Google Cloud SQL, etc.)

### Production Docker Compose Example
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
    ports:
      - "${DB_PORT}:5432"
    restart: always
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
```

Create `.env` file:
```
DB_USER=quickbite_user
DB_PASSWORD=your_strong_password_here
DB_NAME=quickbite
DB_PORT=5432
```

---

## 📝 Common Operations

### Backup Database
```bash
# Create backup
docker-compose exec postgres pg_dump -U quickbite_user -d quickbite > backup_$(date +%Y%m%d_%H%M%S).sql

# Or use pgAdmin GUI (easier)
```

### Restore Database
```bash
# Restore from backup
docker-compose exec -T postgres psql -U quickbite_user -d quickbite < backup_20240324_120000.sql
```

### Export Table as CSV
```sql
-- In pgAdmin Query Tool
\copy (SELECT * FROM restaurants) TO STDOUT WITH CSV HEADER;
```

### Clear All Data (Keep Schema)
```bash
# In pgAdmin Query Tool
TRUNCATE TABLE order_items CASCADE;
TRUNCATE TABLE orders CASCADE;
TRUNCATE TABLE coupon_usage CASCADE;
TRUNCATE TABLE user_favorites CASCADE;
-- ... continue for other tables
```

---

## 🎯 Next Steps

1. ✅ Start Docker containers with `docker-compose up -d`
2. ✅ Access pgAdmin at http://localhost:5050
3. ✅ Explore the database structure
4. ✅ Run sample queries
5. ✅ Connect your application to the database
6. ✅ Set up automated backups
7. ✅ Monitor database performance

---

## 📚 Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [pgAdmin4 Documentation](https://www.pgadmin.org/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

---

## ❓ Getting Help

If you encounter issues:
1. Check [Troubleshooting](#-troubleshooting) section
2. View container logs: `docker-compose logs`
3. Verify Docker status: `docker-compose ps`
4. Check file permissions in project directory
5. Ensure ports 5432 and 5050 are available

---

*Last Updated: March 24, 2026*  
*Docker Setup for QuickBite Database*  
*Version 1.0*
