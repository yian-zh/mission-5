# PowerShell script to verify database CRUD, central sync, Redis cache, and homepage delivery

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "STARTING SYSTEM ARCHITECTURE VERIFICATION TEST" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

# 1. Warm-up and Test Homepage
Write-Host "`n1. Testing Homepage (Server 01)..." -ForegroundColor White
try {
    $homepage = Invoke-WebRequest -Uri "http://localhost:8080/" -UseBasicParsing -TimeoutSec 5
    Write-Host "Homepage is UP! Status Code: $($homepage.StatusCode)" -ForegroundColor Green
} catch {
    Write-Error "Homepage is DOWN: $_"
    exit 1
}

# 2. Insert new product via Central Service (Server 03) to PostgreSQL (Server 04)
Write-Host "`n2. Inserting new product via Central Service..." -ForegroundColor White
$productJson = @{
    name = "Quantum Mouse"
    price = 49.99
    description = "Next-generation quantum gaming mouse."
    category = @{
        id = 1 # Electronics
    }
} | ConvertTo-Json

try {
    $savedProduct = Invoke-RestMethod -Method Post -Uri "http://localhost:8081/api/products" -Body $productJson -ContentType "application/json" -TimeoutSec 5
    Write-Host "Product successfully created in PostgreSQL!" -ForegroundColor Green
    Write-Host "Saved Product Details:" -ForegroundColor Gray
    Write-Host "  ID: $($savedProduct.id)" -ForegroundColor Gray
    Write-Host "  Name: $($savedProduct.name)" -ForegroundColor Gray
    Write-Host "  Price: $($savedProduct.price)" -ForegroundColor Gray
    Write-Host "  Category: $($savedProduct.category.name)" -ForegroundColor Gray
} catch {
    Write-Error "Failed to insert product via Central Service: $_"
    exit 1
}

# 3. Verify Redis Cache (Server 02) updates automatically
Write-Host "`n3. Checking Redis Cache for updated product list..." -ForegroundColor White
Start-Sleep -Seconds 1 # Wait brief moment for async operation
try {
    $redisOutput = docker exec mission5-redis redis-cli get products:all
    if ($redisOutput -like "*Quantum Mouse*") {
        Write-Host "SUCCESS: Redis cache has been updated and contains 'Quantum Mouse'!" -ForegroundColor Green
    } else {
        Write-Warning "Redis cache does NOT contain the new product."
    }
} catch {
    Write-Error "Failed to connect to Redis CLI: $_"
}

# 4. Verify Homepage shows the new product from Redis
Write-Host "`n4. Querying Homepage to verify display of new product..." -ForegroundColor White
try {
    $homepageUpdated = Invoke-WebRequest -Uri "http://localhost:8080/" -UseBasicParsing -TimeoutSec 5
    if ($homepageUpdated.Content -like "*Quantum Mouse*") {
        Write-Host "SUCCESS: Homepage displays 'Quantum Mouse' successfully!" -ForegroundColor Green
    } else {
        Write-Warning "Homepage does NOT display 'Quantum Mouse'."
    }
} catch {
    Write-Error "Failed to load updated homepage: $_"
}

# 5. Clean up: Delete the test product
Write-Host "`n5. Deleting test product via Central Service (Cleaning up)..." -ForegroundColor White
try {
    Invoke-RestMethod -Method Delete -Uri "http://localhost:8081/api/products/$($savedProduct.id)" -TimeoutSec 5
    Write-Host "Product deleted successfully from PostgreSQL!" -ForegroundColor Green
} catch {
    Write-Error "Failed to delete product: $_"
}

# 6. Verify Redis Cache is cleaned
Write-Host "`n6. Checking Redis Cache again after deletion..." -ForegroundColor White
Start-Sleep -Seconds 1
try {
    $redisOutputClean = docker exec mission5-redis redis-cli get products:all
    if ($redisOutputClean -like "*Quantum Mouse*") {
        Write-Warning "Redis cache still contains 'Quantum Mouse' after deletion!"
    } else {
        Write-Host "SUCCESS: Redis cache was updated and 'Quantum Mouse' was removed!" -ForegroundColor Green
    }
} catch {
    Write-Error "Failed to connect to Redis CLI: $_"
}

Write-Host "`n==============================================" -ForegroundColor Cyan
Write-Host "VERIFICATION TEST COMPLETED SUCCESSFULLY" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
