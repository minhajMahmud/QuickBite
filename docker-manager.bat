@echo off
REM QuickBite Docker Manager - Windows Batch Script
REM Usage: docker-manager.bat [command]

setlocal enabledelayedexpansion
cd /d "%~dp0"

set "COMMAND=%1"
if "%COMMAND%"=="" set "COMMAND=help"

if /i "%COMMAND%"=="help" goto :show_help
if /i "%COMMAND%"=="start" goto :start_containers
if /i "%COMMAND%"=="stop" goto :stop_containers
if /i "%COMMAND%"=="restart" goto :restart_containers
if /i "%COMMAND%"=="status" goto :show_status
if /i "%COMMAND%"=="logs" goto :show_logs
if /i "%COMMAND%"=="shell" goto :connect_shell
if /i "%COMMAND%"=="backup" goto :create_backup
if /i "%COMMAND%"=="reset" goto :reset_database
if /i "%COMMAND%"=="clean" goto :clean_everything

echo Unknown command: %COMMAND%
echo.
goto :show_help

:show_help
cls
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║     QuickBite Docker Manager - Windows Batch Script        ║
echo ╚════════════════════════════════════════════════════════════╝
echo.
echo Commands:
echo   start              Start all containers
echo   stop               Stop all containers
echo   restart            Restart containers
echo   status             Show container status
echo   logs               View container logs
echo   shell              Connect to PostgreSQL shell
echo   backup             Create database backup
echo   reset              Reset database ^(delete all data^)
echo   clean              Remove all containers and volumes
echo   help               Show this help message
echo.
echo Examples:
echo   docker-manager.bat start
echo   docker-manager.bat backup
echo   docker-manager.bat shell
echo.
goto :end

:start_containers
cls
echo.
echo [*] Starting Docker containers...
docker-compose up -d
timeout /t 2 /nobreak
docker-compose ps
echo.
echo [+] Containers started!
echo.
echo Access Points:
echo   pgAdmin4:   http://localhost:5050
echo   PostgreSQL: localhost:5432
echo.
goto :end

:stop_containers
cls
echo.
echo [*] Stopping Docker containers...
docker-compose stop
echo.
echo [+] Containers stopped!
echo.
goto :end

:restart_containers
cls
echo.
echo [*] Restarting Docker containers...
docker-compose restart
timeout /t 2 /nobreak
docker-compose ps
echo.
echo [+] Containers restarted!
echo.
goto :end

:show_status
cls
echo.
echo [*] Container Status:
docker-compose ps
echo.
echo [*] Access Information:
echo   pgAdmin4:   http://localhost:5050
echo   PostgreSQL: localhost:5432
echo   User:       quickbite_user
echo   Database:   quickbite
echo.
goto :end

:show_logs
cls
echo.
echo [*] Showing container logs (press Ctrl+C to exit)...
docker-compose logs -f
goto :end

:connect_shell
cls
echo.
echo [*] Connecting to PostgreSQL shell...
echo [*] Type \q to exit
echo.
docker-compose exec postgres psql -U quickbite_user -d quickbite
goto :end

:create_backup
cls
echo.
echo [*] Creating database backup...
set "TIMESTAMP=%DATE:~-4%%DATE:~-10,2%%DATE:~-7,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%"
docker-compose exec -T postgres pg_dump -U quickbite_user -d quickbite > backup_%TIMESTAMP%.sql
echo.
echo [+] Backup created successfully!
echo [*] File: backup_%TIMESTAMP%.sql
echo.
goto :end

:reset_database
cls
echo.
echo [!] WARNING: This will DELETE all data!
set /p confirm="Are you sure? (type 'yes' to confirm): "
if /i not "%confirm%"=="yes" (
    echo.
    echo [-] Reset cancelled
    echo.
    goto :end
)
echo.
echo [*] Resetting database...
docker-compose down -v
docker-compose up -d
timeout /t 5 /nobreak
echo.
echo [+] Database reset complete!
echo [*] New sample data has been initialized.
echo.
goto :end

:clean_everything
cls
echo.
echo [!] WARNING: This will DELETE all containers and data!
set /p confirm="Are you sure? (type 'yes' to confirm): "
if /i not "%confirm%"=="yes" (
    echo.
    echo [-] Cleanup cancelled
    echo.
    goto :end
)
echo.
echo [*] Cleaning up...
docker-compose down -v
echo.
echo [+] Cleanup complete!
echo.
goto :end

:end
