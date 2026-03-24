# QuickBite Docker Architecture

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Your Computer                                │
│                  (Windows/Mac/Linux)                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │         Docker Engine / Docker Desktop                  │   │
│  │                                                         │   │
│  │  ┌─────────────────────────────────────────────────┐   │   │
│  │  │  Virtual Network: quickbite_network            │   │   │
│  │  │                                                 │   │   │
│  │  │  ┌──────────────────────┐  ┌──────────────────┐ │   │   │
│  │  │  │  PostgreSQL 16       │  │  pgAdmin4        │ │   │   │
│  │  │  │  Container           │  │  Container       │ │   │   │
│  │  │  │                      │  │                  │ │   │   │
│  │  │  │ Port: 5432          │  │ Port: 80/5050   │ │   │   │
│  │  │  │                      │  │                  │ │   │   │
│  │  │  │ ┌────────────────┐  │  │ ┌──────────────┐ │ │   │   │
│  │  │  │ │ quickbite DB   │  │  │ │ Web UI       │ │ │   │   │
│  │  │  │ │ 20 Tables      │  │  │ │ Browser      │ │ │   │   │
│  │  │  │ │ Sample Data    │  │  │ │ Management   │ │ │   │   │
│  │  │  │ └────────────────┘  │  │ └──────────────┘ │ │   │   │
│  │  │  │ Volume:             │  │ Volume:          │ │   │   │
│  │  │  │ postgres_data       │  │ pgadmin_data     │ │   │   │
│  │  │  └──────────────────────┘  └──────────────────┘ │   │   │
│  │  │                      ↔ Network                    │   │   │
│  │  │                    Connection                     │   │   │
│  │  └─────────────────────────────────────────────────┘   │   │
│  │                                                         │   │
│  │  Volumes (Persistent Storage)                          │   │
│  │  ├─ postgres_data/ (PostgreSQL files)                  │   │
│  │  └─ pgadmin_data/ (pgAdmin configuration)              │   │
│  │                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                   │
│  Host Ports (Access from Your Machine)                           │
│  ├─ localhost:5432  → PostgreSQL Container:5432                 │
│  └─ localhost:5050  → pgAdmin Container:80                      │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘

                             ↓

┌─────────────────────────────────────────────────────────────────┐
│                    Your Applications                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐    │
│  │  Flutter App │     │  Backend API │     │  Web Portal  │    │
│  │  (Mobile)    │────→│  (Node/Py)   │────→│  (React)     │    │
│  │              │     │              │     │              │    │
│  └──────────────┘     └──────────────┘     └──────────────┘    │
│        ↓                      ↓                    ↓              │
│   Connection               Connection          Connection       │
│   via API                 localhost:5432       localhost:5432    │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    User Browser                             │
│                  (pgAdmin4 Interface)                       │
└────────────────────────────┬────────────────────────────────┘
                             │
                      HTTP Request
                             │
                             ↓
┌─────────────────────────────────────────────────────────────┐
│              pgAdmin4 Container                             │
│  (http://localhost:5050)                                   │
│                                                             │
│  ├─ Web Server (Nginx/Apache)                              │
│  ├─ pgAdmin4 Application                                   │
│  └─ Web Interface                                           │
└────────────────────────────┬────────────────────────────────┘
                             │
                      PostgreSQL Protocol
                       (Port 5432)
                             │
                             ↓
┌─────────────────────────────────────────────────────────────┐
│         PostgreSQL 16 Container                            │
│  (localhost:5432)                                          │
│                                                             │
│  ├─ Database Engine                                        │
│  ├─ Query Processor                                        │
│  ├─ Transaction Manager                                    │
│  │                                                         │
│  └─ Database Files (Persistent Volume)                     │
│     ├─ tables/                                             │
│     ├─ indexes/                                            │
│     ├─ logs/                                               │
│     └─ data_files/                                         │
│                                                             │
│  20 Tables:                                                │
│  ├─ users                    ├─ restaurants                │
│  ├─ user_addresses           ├─ food_items                │
│  ├─ user_favorites           ├─ categories                │
│  ├─ orders                   ├─ delivery_agents            │
│  ├─ order_items              ├─ coupons                    │
│  ├─ ratings (3 types)        ├─ admin_users               │
│  ├─ notifications            └─ revenue_statistics        │
│  └─ ... and more                                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Container Communication

```
                ┌──────────────────────────┐
                │  quickbite_network       │
                │  (Docker Virtual Bridge) │
                └──────────────────────────┘
                   ↑                    ↑
                   │                    │
        ┌──────────┴───────┐    ┌───────┴──────────┐
        │                  │    │                  │
        │                  │    │                  │
   ┌────▼────────┐     ┌──▼────▼──┐          ┌────▼────────┐
   │  PostgreSQL │     │ Network  │          │  pgAdmin4   │
   │ Container   │────→│Interface│◄─────────│ Container   │
   │ 172.XX.0.2  │     │          │          │ 172.XX.0.3  │
   │             │     └──────────┘          │             │
   │ Port: 5432  │                           │ Port: 80    │
   └─────────────┘                           └─────────────┘
        ↑                                           ↑
        │                                           │
   Host:5432                                   Host:5050
   mapping                                     mapping
        │                                           │
        └───────────────┬──────────────────────────┘
                        │
                    Your Machine
```

---

## File Mount Binding

```
Host Machine (Windows)          Docker Container
─────────────────────────      ──────────────────

e:\quickbite\
├── database_schema.sql    ──→  /docker-entrypoint-initdb.d/01-schema.sql
├── init-data.sql          ──→  /docker-entrypoint-initdb.d/02-init-data.sql
└── pgadmin_servers.json   ──→  /pgadmin4/servers.json

Volumes (Docker Managed):

postgres_data (Host)       ←←→  /var/lib/postgresql/data (PostgreSQL)
pgadmin_data (Host)        ←←→  /var/lib/pgadmin (pgAdmin)
```

---

## Startup Sequence

```
┌─ START: docker-compose up -d
│
├─ STEP 1: Create Network
│  └─→ quickbite_network created
│
├─ STEP 2: Create Volumes
│  ├─→ postgres_data created
│  └─→ pgadmin_data created
│
├─ STEP 3: Start PostgreSQL Container
│  ├─→ Pull image: postgres:16-alpine
│  ├─→ Mount volumes
│  ├─→ Set environment variables
│  ├─→ Run initialization scripts:
│  │   ├─→ 01-schema.sql (create tables)
│  │   └─→ 02-init-data.sql (load sample data)
│  ├─→ Start PostgreSQL server
│  └─→ Health check passes ✓
│
├─ STEP 4: Start pgAdmin Container
│  ├─→ Pull image: dpage/pgadmin4:latest
│  ├─→ Mount volumes
│  ├─→ Load server configuration
│  ├─→ Connect to PostgreSQL network
│  └─→ Start web server ✓
│
└─ COMPLETE: Ready to access!
   ├─→ PostgreSQL: localhost:5432
   └─→ pgAdmin4: http://localhost:5050
```

---

## Service Dependencies

```
pgAdmin4 Container
        │
        └─ depends_on: postgres (service_healthy)
                │
                ├─ Waits for health check
                │
                └─→ PostgreSQL Container
                     ├─ Database initialized
                     ├─ Schema created
                     ├─ Sample data loaded
                     └─ Ready for connections
```

---

## Database Schema Structure

```
PostgreSQL Database: quickbite
│
├─ Schema: public
│  │
│  ├─ Tables (20):
│  │  │
│  │  ├─ Core Entities
│  │  │  ├─ users (3 users)
│  │  │  ├─ restaurants (4 restaurants)
│  │  │  ├─ food_items (11 items)
│  │  │  └─ categories (6 categories)
│  │  │
│  │  ├─ Orders
│  │  │  ├─ orders (4 orders)
│  │  │  ├─ order_items (line items)
│  │  │  ├─ order_status_history
│  │  │  └─ coupon_usage
│  │  │
│  │  ├─ Delivery
│  │  │  ├─ delivery_agents (3 agents)
│  │  │  ├─ delivery_agent_ratings
│  │  │  └─ operating_hours
│  │  │
│  │  ├─ Ratings & Reviews
│  │  │  ├─ food_item_ratings
│  │  │  ├─ restaurant_ratings
│  │  │  └─ delivery_agent_ratings
│  │  │
│  │  ├─ Management
│  │  │  ├─ user_addresses
│  │  │  ├─ user_favorites
│  │  │  ├─ coupons
│  │  │  ├─ notifications
│  │  │  ├─ admin_users
│  │  │  ├─ admin_activities
│  │  │  └─ revenue_statistics
│  │  │
│  │  └─ Indexes (40+)
│  │     ├─ Primary keys on all tables
│  │     ├─ Foreign keys for relationships
│  │     ├─ Performance indexes on:
│  │     │  ├─ email fields
│  │     │  ├─ status fields
│  │     │  ├─ timestamps
│  │     │  └─ frequently queried columns
│  │
│  └─ Views (3):
│     ├─ active_users
│     ├─ popular_restaurants
│     └─ recent_orders
│
├─ Volumes:
│  ├─ postgres_data/ (Database files, indices, logs)
│  └─ pgadmin_data/ (Configuration, bookmarks, history)
│
└─ Users:
   ├─ quickbite_user (application user)
   └─ postgres (system user)
```

---

## Resource Allocation

```
PostgreSQL Container
├─ CPU: Unlimited (host available)
├─ Memory: Unlimited (host available)
├─ Storage: postgres_data volume
│  └─ Initial: ~50MB
│  └─ Grows with data (estimated 1GB at scale)
└─ Network: quickbite_network

pgAdmin4 Container
├─ CPU: Unlimited (host available)
├─ Memory: Unlimited (host available)
├─ Storage: pgadmin_data volume
│  └─ ~100-200MB
└─ Network: quickbite_network

Recommended Host Resources
├─ CPU: 2+ cores
├─ RAM: 4GB+ (2GB minimum)
├─ Disk: SSD with 10GB+ free space
└─ Network: Standard internet connection
```

---

## Port Mapping

```
Host Machine              Container
───────────────           ──────────

localhost:5432    ←────→  postgres:5432
(PostgreSQL)              (PostgreSQL)

localhost:5050    ←────→  pgadmin:80
(pgAdmin4 HTTP)           (pgAdmin4 Web)

(Ports configurable in docker-compose.yml)
```

---

## Environment Variables Flow

```
docker-compose.yml (Configuration)
│
├─ POSTGRES_USER: quickbite_user
│  └─→ PostgreSQL Container env
│
├─ POSTGRES_PASSWORD: quickbite_password_2024
│  └─→ PostgreSQL Container env
│
├─ POSTGRES_DB: quickbite
│  └─→ PostgreSQL Container env
│
├─ PGADMIN_DEFAULT_EMAIL: admin@quickbite.com
│  └─→ pgAdmin Container env
│
└─ PGADMIN_DEFAULT_PASSWORD: admin_password_2024
   └─→ pgAdmin Container env

.env File (Optional Overrides)
│
├─ DB_USER
├─ DB_PASSWORD
├─ PGADMIN_EMAIL
└─ PGADMIN_PASSWORD
```

---

## Data Persistence Flow

```
Initial Run (First Time)
│
├─ docker-compose up -d
│  ├─ Create postgres_data volume
│  ├─ Create pgadmin_data volume
│  │
│  ├─ PostgreSQL Container starts
│  │  ├─ Run 01-schema.sql
│  │  │  └─→ Create 20 tables with indexes
│  │  │
│  │  ├─ Run 02-init-data.sql
│  │  │  └─→ Insert sample data
│  │  │
│  │  └─→ Database files written to postgres_data volume
│  │
│  └─ pgAdmin Container starts
│     └─→ Configuration written to pgadmin_data volume
│
Subsequent Runs
│
├─ docker-compose start (or up -d again)
│  │
│  ├─ Data persists from volumes
│  ├─ No re-initialization
│  └─ Database ready instantly
│
Complete Cleanup
│
└─ docker-compose down -v
   ├─ Containers removed
   ├─ Network removed
   └─ Volumes DELETED (data lost)

Data Backup
│
└─ docker-compose exec postgres pg_dump
   └─→ Creates SQL backup file (portable)
```

---

## Help & Diagnostics

```
View Status
└─ docker-compose ps

View Logs
├─ docker-compose logs (all)
├─ docker-compose logs postgres
├─ docker-compose logs pgadmin
└─ docker-compose logs -f (follow)

Container Communication Test
└─ docker-compose exec pgadmin ping postgres

Verify Volumes
└─ docker volume ls
└─ docker volume inspect postgres_data

Verify Network
└─ docker network ls
└─ docker network inspect quickbite_network

Test PostgreSQL Connection
└─ docker-compose exec postgres psql -U quickbite_user -d quickbite -c "SELECT 1"
```

---

*Docker Architecture Diagram - March 24, 2026*
*QuickBite Database Setup Version 1.0*
