# QuickBite Backend Startup Script
# This script starts Docker, launches all services (PostgreSQL, pgAdmin, Backend),
# and verifies database connectivity with data persistence

Write-Host "================================" -ForegroundColor Cyan
Write-Host "  QuickBite Backend Launcher" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if Docker is running
function Check-DockerRunning {
    try {
        docker ps > $null 2>&1
        return $true
    }
    catch {
        return $false
    }
}

# Function to start Docker Desktop
function Start-DockerDesktop {
    Write-Host "Starting Docker Desktop..." -ForegroundColor Yellow
    
    $dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dockerPath) {
        & $dockerPath
        Write-Host "Waiting for Docker daemon to start..." -ForegroundColor Yellow
        
        # Wait up to 60 seconds for Docker to be ready
        $maxAttempts = 60
        $attempt = 0
        while (-not (Check-DockerRunning) -and $attempt -lt $maxAttempts) {
            Start-Sleep -Seconds 1
            $attempt++
            Write-Host "." -NoNewline
        }
        Write-Host ""
        
        if (Check-DockerRunning) {
            Write-Host "✓ Docker Desktop started successfully" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "✗ Docker Desktop failed to start within 60 seconds" -ForegroundColor Red
            return $false
        }
    }
    else {
        Write-Host "✗ Docker Desktop not found at: $dockerPath" -ForegroundColor Red
        return $false
    }
}

# Check if Docker is running
if (-not (Check-DockerRunning)) {
    Write-Host "Docker daemon is not running." -ForegroundColor Red
    if (-not (Start-DockerDesktop)) {
        Write-Host "Please start Docker Desktop manually and try again." -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "✓ Docker is running" -ForegroundColor Green
}

Write-Host ""
Write-Host "Starting QuickBite services..." -ForegroundColor Yellow
Write-Host ""

# Navigate to the quickbite directory
Set-Location "e:\quickbite"

# Start all services with docker-compose
Write-Host "Launching: PostgreSQL, pgAdmin, and Backend..." -ForegroundColor Cyan
docker-compose up -d postgres pgadmin backend

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✓ Services started successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Service URLs:" -ForegroundColor Cyan
    Write-Host "  - Backend API:     http://localhost:3000" -ForegroundColor White
    Write-Host "  - pgAdmin (DB UI): http://localhost:5050" -ForegroundColor White
    Write-Host ""
    Write-Host "Database Details:" -ForegroundColor Cyan
    Write-Host "  - Host: localhost:5433 (from host)" -ForegroundColor White
    Write-Host "  - Database: quickbite" -ForegroundColor White
    Write-Host "  - User: quickbite_user" -ForegroundColor White
    Write-Host ""
    
    # Wait a few seconds for services to stabilize
    Write-Host "Waiting for services to stabilize..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    
    # Verify database connectivity and data persistence
    Write-Host "Verifying database connectivity..." -ForegroundColor Cyan
    try {
        $result = docker exec quickbite_postgres psql -U quickbite_user -d quickbite -c "SELECT COUNT(*) AS user_count FROM public.users;" 2>&1
        if ($result -match "user_count") {
            Write-Host "✓ Database verified - Users table is accessible" -ForegroundColor Green
            Write-Host ""
            Write-Host "Data Persistence Status:" -ForegroundColor Green
            Write-Host $result | Select-String "user_count|---" | ForEach-Object { "  $_" }
        }
        else {
            Write-Host "⚠ Could not verify database table" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "⚠ Database verification skipped (services still starting)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Backend is ready! Users data will be persisted in PostgreSQL." -ForegroundColor Green
    Write-Host ""
}
else {
    Write-Host "✗ Failed to start services" -ForegroundColor Red
    exit 1
}

# Keep terminal open
Write-Host "Press Ctrl+C to stop the script" -ForegroundColor Gray
while ($true) { Start-Sleep -Seconds 10 }
