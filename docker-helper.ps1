#!/usr/bin/env pwsh
# QuickBite Docker Helper Script for Windows PowerShell
# Usage: ./docker-helper.ps1 [command]

param(
    [Parameter(Position = 0)]
    [string]$Command = "help"
)

$ErrorActionPreference = "Stop"

function Show-Help {
    Write-Host @"
╔════════════════════════════════════════════════════════════════╗
║          QuickBite Docker Helper - PowerShell Script            ║
╚════════════════════════════════════════════════════════════════╝

Available Commands:

  DATABASE MANAGEMENT:
    start              - Start all containers
    stop               - Stop all containers
    restart            - Restart all containers
    logs               - View container logs
    logs-postgres      - View PostgreSQL logs
    logs-pgadmin       - View pgAdmin logs
    status             - Show container status

  DATABASE ACCESS:
    shell              - Access PostgreSQL shell
    query <sql>        - Execute SQL query

  BACKUP & RESTORE:
    backup             - Create database backup
    restore <file>    - Restore from backup file
    
  DATA OPERATIONS:
    init-data          - Initialize sample data
    reset              - Reset database (delete all data)
    
  MONITORING:
    stats              - Show database statistics
    size               - Show database size
    connections        - List active connections
    
  UTILITIES:
    clean              - Remove all containers and volumes
    env                - Create .env from .env.example
    help               - Show this help message

Examples:
    ./docker-helper.ps1 start
    ./docker-helper.ps1 backup
    ./docker-helper.ps1 shell
    ./docker-helper.ps1 query "SELECT * FROM users;"

"@
}

function Start-Containers {
    Write-Host "🚀 Starting Docker containers..." -ForegroundColor Green
    docker-compose up -d
    Start-Sleep -Seconds 2
    docker-compose ps
    Write-Host "✅ Containers started!" -ForegroundColor Green
}

function Stop-Containers {
    Write-Host "⏹️  Stopping Docker containers..." -ForegroundColor Yellow
    docker-compose stop
    Write-Host "✅ Containers stopped!" -ForegroundColor Green
}

function Restart-Containers {
    Write-Host "🔄 Restarting Docker containers..." -ForegroundColor Yellow
    docker-compose restart
    Start-Sleep -Seconds 2
    docker-compose ps
    Write-Host "✅ Containers restarted!" -ForegroundColor Green
}

function Show-Logs {
    param([string]$Service = "")
    
    if ($Service) {
        Write-Host "📋 Showing logs for $Service..." -ForegroundColor Cyan
        docker-compose logs -f $Service
    }
    else {
        Write-Host "📋 Showing all logs..." -ForegroundColor Cyan
        docker-compose logs -f
    }
}

function Show-Status {
    Write-Host "📊 Container Status:" -ForegroundColor Cyan
    docker-compose ps
    Write-Host ""
    Write-Host "Access Points:" -ForegroundColor Cyan
    Write-Host "  PostgreSQL: localhost:5432" -ForegroundColor White
    Write-Host "  pgAdmin4:   http://localhost:5050" -ForegroundColor White
    Write-Host ""
    Write-Host "Credentials:" -ForegroundColor Cyan
    Write-Host "  PostgreSQL:" -ForegroundColor White
    Write-Host "    Username: quickbite_user" -ForegroundColor Gray
    Write-Host "    Database: quickbite" -ForegroundColor Gray
    Write-Host "  pgAdmin:" -ForegroundColor White
    Write-Host "    Email: admin@quickbite.com" -ForegroundColor Gray
}

function Connect-PostgresShell {
    Write-Host "🔌 Connecting to PostgreSQL shell..." -ForegroundColor Cyan
    Write-Host "Type \q to exit" -ForegroundColor Yellow
    docker-compose exec postgres psql -U quickbite_user -d quickbite
}

function Execute-Query {
    param([string]$Query)
    
    if ([string]::IsNullOrEmpty($Query)) {
        Write-Host "❌ No query provided" -ForegroundColor Red
        return
    }
    
    Write-Host "🔍 Executing query..." -ForegroundColor Cyan
    docker-compose exec -T postgres psql -U quickbite_user -d quickbite -c $Query
}

function Create-Backup {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = "backup_$timestamp.sql"
    
    Write-Host "💾 Creating backup: $backupFile" -ForegroundColor Green
    docker-compose exec -T postgres pg_dump -U quickbite_user -d quickbite | Out-File -FilePath $backupFile -Encoding UTF8
    
    $size = (Get-Item $backupFile).Length / 1MB
    Write-Host "✅ Backup created successfully!" -ForegroundColor Green
    Write-Host "📁 File: $backupFile (Size: $([math]::Round($size, 2)) MB)" -ForegroundColor Cyan
}

function Restore-Backup {
    param([string]$FilePath)
    
    if ([string]::IsNullOrEmpty($FilePath)) {
        Write-Host "❌ No file path provided" -ForegroundColor Red
        return
    }
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "❌ File not found: $FilePath" -ForegroundColor Red
        return
    }
    
    Write-Host "📂 Restoring from: $FilePath" -ForegroundColor Yellow
    $response = Read-Host "⚠️  This will overwrite existing data. Continue? (y/n)"
    
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Host "❌ Restore cancelled" -ForegroundColor Yellow
        return
    }
    
    Get-Content $FilePath | docker-compose exec -T postgres psql -U quickbite_user -d quickbite
    Write-Host "✅ Database restored successfully!" -ForegroundColor Green
}

function Reset-Database {
    Write-Host "⚠️  WARNING: This will DELETE all data and reinitialize the database!" -ForegroundColor Red
    $response = Read-Host "Are you sure? (type 'yes' to confirm)"
    
    if ($response -ne "yes") {
        Write-Host "❌ Reset cancelled" -ForegroundColor Yellow
        return
    }
    
    Write-Host "🔄 Resetting database..." -ForegroundColor Yellow
    docker-compose down -v
    docker-compose up -d
    
    Start-Sleep -Seconds 5
    Write-Host "✅ Database reset complete! New sample data has been initialized." -ForegroundColor Green
}

function Show-DatabaseStats {
    Write-Host "📊 Database Statistics:" -ForegroundColor Cyan
    
    $query = @"
SELECT schemaname, tablename, 
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
       (SELECT count(*) FROM information_schema.columns 
        WHERE table_schema=schemaname AND table_name=tablename) as columns
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
"@
    
    Execute-Query $query
}

function Show-DatabaseSize {
    Write-Host "💾 Database Size:" -ForegroundColor Cyan
    
    $query = @"
SELECT datname as database, 
       pg_size_pretty(pg_database_size(datname)) as size 
FROM pg_database 
WHERE datname = 'quickbite';
"@
    
    Execute-Query $query
}

function Show-Connections {
    Write-Host "🔌 Active Database Connections:" -ForegroundColor Cyan
    
    $query = @"
SELECT datname, usename, application_name, state, query_start 
FROM pg_stat_activity 
WHERE datname = 'quickbite' 
ORDER BY query_start DESC;
"@
    
    Execute-Query $query
}

function Clean-Everything {
    Write-Host "⚠️  WARNING: This will DELETE all containers and volumes!" -ForegroundColor Red
    $response = Read-Host "Are you sure? (type 'yes' to confirm)"
    
    if ($response -ne "yes") {
        Write-Host "❌ Cleanup cancelled" -ForegroundColor Yellow
        return
    }
    
    Write-Host "🧹 Cleaning up..." -ForegroundColor Yellow
    docker-compose down -v
    Write-Host "✅ Cleanup complete!" -ForegroundColor Green
}

function Create-EnvFile {
    if (-not (Test-Path ".env.example")) {
        Write-Host "❌ .env.example not found" -ForegroundColor Red
        return
    }
    
    if (Test-Path ".env") {
        Write-Host "⚠️  .env file already exists" -ForegroundColor Yellow
        return
    }
    
    Copy-Item ".env.example" ".env"
    Write-Host "✅ Created .env file from .env.example" -ForegroundColor Green
    Write-Host "📝 Edit .env file to customize settings" -ForegroundColor Cyan
}

# Execute command
switch ($Command.ToLower()) {
    "help" { Show-Help }
    "start" { Start-Containers }
    "stop" { Stop-Containers }
    "restart" { Restart-Containers }
    "logs" { Show-Logs }
    "logs-postgres" { Show-Logs "postgres" }
    "logs-pgadmin" { Show-Logs "pgadmin" }
    "status" { Show-Status }
    "shell" { Connect-PostgresShell }
    "query" { Execute-Query $args[0] }
    "backup" { Create-Backup }
    "restore" { Restore-Backup $args[0] }
    "reset" { Reset-Database }
    "stats" { Show-DatabaseStats }
    "size" { Show-DatabaseSize }
    "connections" { Show-Connections }
    "clean" { Clean-Everything }
    "env" { Create-EnvFile }
    default {
        Write-Host "❌ Unknown command: $Command" -ForegroundColor Red
        Write-Host ""
        Show-Help
    }
}
