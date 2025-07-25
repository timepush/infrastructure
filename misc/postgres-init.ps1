# PowerShell script to apply schema.sql to the running Postgres container

# Load .env variables
$envVars = @{}
Get-Content .env | ForEach-Object {
    if ($_ -match '^(?!#)\s*([^=]+)=(.*)$') {
        $key = $matches[1].Trim()
        $val = $matches[2].Trim()
        $envVars[$key] = $val
    }
}

# Get Postgres container name
$container = docker ps --filter "ancestor=postgres:15" --format "{{.Names}}"
if (-not $container) {
    Write-Host "No running Postgres container found. Please start it first."
    exit 1
}

# Copy schema.sql into the container
docker cp schema.sql ${container}:/schema.sql

# Run psql to apply the schema
$PGUSER = $envVars['POSTGRES_USER']
$PGDB = $envVars['POSTGRES_DB']
$PGPASSWORD = $envVars['POSTGRES_PASSWORD']

# Set password env for the exec
$env:PGPASSWORD = $PGPASSWORD
docker exec -e PGPASSWORD=$PGPASSWORD -it $container psql -U $PGUSER -d $PGDB -f /schema.sql

Write-Host "Schema applied to Postgres database $PGDB."
