# PowerShell script to benchmark queries before and after database indexing

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "RUNNING DATABASE INDEXING BENCHMARK" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

# Set environment variables for docker pg call
$pgCommand = "docker exec -i mission5-postgres psql -U postgres -d mission5_db"

# 1. Run EXPLAIN ANALYZE before creating indexes
Write-Host "`n[Phase 1] Fetching query execution plans BEFORE indexing..." -ForegroundColor Yellow

# Query 1: Filter by category_id (unindexed)
$q1 = "EXPLAIN ANALYZE SELECT * FROM products WHERE category_id = 4;"
$plan1_before = & cmd /c "$pgCommand -c `"$q1`""

# Query 2: Filter by exact name (unindexed)
# Let's find one existing product name to search
$sample_name = & cmd /c "$pgCommand -t -c `"SELECT name FROM products LIMIT 1;`""
$sample_name = $sample_name.Trim()
Write-Host "  Using sample search name: '$sample_name'" -ForegroundColor Gray

$q2 = "EXPLAIN ANALYZE SELECT * FROM products WHERE name = '$sample_name';"
$plan2_before = & cmd /c "$pgCommand -c `"$q2`""

# Query 3: Order by created_at (unindexed)
$q3 = "EXPLAIN ANALYZE SELECT * FROM products ORDER BY created_at DESC LIMIT 100;"
$plan3_before = & cmd /c "$pgCommand -c `"$q3`""

# Write Before results to a file
$before_report = @"
==================================================
QUERY EXECUTION PLANS BEFORE INDEXING (SEQ SCANS)
==================================================

1. Filter by category_id:
Query: $q1
Plan:
$($plan1_before -join "`n")

2. Filter by name:
Query: $q2
Plan:
$($plan2_before -join "`n")

3. Order by created_at DESC:
Query: $q3
Plan:
$($plan3_before -join "`n")
"@
$before_report | Out-File -FilePath "./db/benchmark_before.txt" -Encoding utf8
Write-Host "Before-indexing plans saved to ./db/benchmark_before.txt" -ForegroundColor Green

# 2. Create the indexes
Write-Host "`n[Phase 2] Creating indexes on PostgreSQL..." -ForegroundColor Yellow
$idx1 = "CREATE INDEX idx_products_category ON products(category_id);"
$idx2 = "CREATE INDEX idx_products_name ON products(name);"
$idx3 = "CREATE INDEX idx_products_created_at ON products(created_at);"

Write-Host "  Creating index on category_id..." -ForegroundColor Gray
& cmd /c "$pgCommand -c `"$idx1`"" | Out-Null

Write-Host "  Creating index on name..." -ForegroundColor Gray
& cmd /c "$pgCommand -c `"$idx2`"" | Out-Null

Write-Host "  Creating index on created_at..." -ForegroundColor Gray
& cmd /c "$pgCommand -c `"$idx3`"" | Out-Null

Write-Host "Indexes successfully created!" -ForegroundColor Green

# 3. Run EXPLAIN ANALYZE after creating indexes
Write-Host "`n[Phase 3] Fetching query execution plans AFTER indexing..." -ForegroundColor Yellow

$plan1_after = & cmd /c "$pgCommand -c `"$q1`""
$plan2_after = & cmd /c "$pgCommand -c `"$q2`""
$plan3_after = & cmd /c "$pgCommand -c `"$q3`""

# Write After results to a file
$after_report = @"
==================================================
QUERY EXECUTION PLANS AFTER INDEXING (INDEX SCANS)
==================================================

1. Filter by category_id:
Query: $q1
Plan:
$($plan1_after -join "`n")

2. Filter by name:
Query: $q2
Plan:
$($plan2_after -join "`n")

3. Order by created_at DESC:
Query: $q3
Plan:
$($plan3_after -join "`n")
"@
$after_report | Out-File -FilePath "./db/benchmark_after.txt" -Encoding utf8
Write-Host "After-indexing plans saved to ./db/benchmark_after.txt" -ForegroundColor Green

# 4. Generate query load to feed pgBadger
Write-Host "`n[Phase 4] Generating database activity load for pgBadger..." -ForegroundColor Yellow
Write-Host "  Running 500 search queries on indexed tables..." -ForegroundColor Gray
for ($i = 1; $i -le 500; $i++) {
    # Query randomly categories and names
    $cat = ($i % 5) + 1
    & cmd /c "$pgCommand -c `"SELECT * FROM products WHERE category_id = $cat LIMIT 10;`"" | Out-Null
}
Write-Host "  Activity generation complete!" -ForegroundColor Green

# 5. Extract logs and run pgBadger
Write-Host "`n[Phase 5] Extracting logs and running pgBadger..." -ForegroundColor Yellow
& ./db/run-pgbadger.ps1

Write-Host "`n==============================================" -ForegroundColor Cyan
Write-Host "BENCHMARK COMPLETED SUCCESSFULLY" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
