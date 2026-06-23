# PowerShell script to extract Postgres logs and generate pgBadger HTML report

Write-Host "Extracting PostgreSQL logs from container..." -ForegroundColor Cyan
if (docker ps -q -f name=mission5-postgres) {
    # Create db folder if not exists
    New-Item -ItemType Directory -Force -Path "./db" | Out-Null
    
    # Copy the log file from the container to the host
    docker cp mission5-postgres:/var/lib/postgresql/data/log/postgresql.log ./db/postgresql.log
    
    if (Test-Path "./db/postgresql.log") {
        Write-Host "Logs successfully extracted to ./db/postgresql.log" -ForegroundColor Green
        
        Write-Host "Running pgBadger inside alpine container to generate HTML report..." -ForegroundColor Cyan
        # Run pgBadger using Alpine with Perl downloaded dynamically
        docker run --rm -v "${PWD}/db:/data" alpine sh -c "apk add --no-cache perl wget && wget -q https://raw.githubusercontent.com/darold/pgbadger/master/pgbadger -O /usr/local/bin/pgbadger && chmod +x /usr/local/bin/pgbadger && pgbadger /data/postgresql.log -o /data/report.html"
        
        if (Test-Path "./db/report.html") {
            Write-Host "pgBadger report generated successfully at ./db/report.html!" -ForegroundColor Green
        } else {
            Write-Warning "pgBadger finished but report.html was not created."
        }
    } else {
        Write-Error "Failed to extract log file from PostgreSQL container."
    }
} else {
    Write-Error "The container 'mission5-postgres' is not running. Please start it using 'docker compose up -d' first."
}
