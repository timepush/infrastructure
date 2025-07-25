# Load .env variables into a hashtable
$envVars = @{}
Get-Content .env | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]*)=(.*)$') {
        $key = $matches[1].Trim()
        $val = $matches[2].Trim()
        $envVars[$key] = $val
    }
}

# Read the template
$template = Get-Content clickhouse-init.template.sql -Raw

# Replace variables in the template
foreach ($key in $envVars.Keys) {
    $template = $template -replace "\$\{${key}\}", [regex]::Escape($envVars[$key])
}

# Save the result
Set-Content -Path clickhouse-init.sql -Value $template

# Get the running ClickHouse container name
$container = docker ps --filter "ancestor=clickhouse/clickhouse-server:latest" --format "{{.Names}}"

if (-not $container) {
    Write-Host "No running ClickHouse container found. Please start it first."
    exit 1
}

# Copy the SQL file into the container
docker cp clickhouse-init.sql ${container}:/clickhouse-init.sql
docker exec -it $container clickhouse-client --multiquery --queries-file /clickhouse-init.sql

Write-Host "SQL file copied to container. To execute, run:"
Write-Host "docker exec -it $container clickhouse-client --multiquery --queries-file /clickhouse-init.sql"