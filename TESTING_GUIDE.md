# Mission-5 Testing and Screenshot Guide

This guide details how to run the automated testing and benchmarking scripts already in your repository, check database state, and capture the exact screenshots required for your submission PDF.

---

## Part 1: How to Run the System Locally

To ensure the automated testing and benchmarking scripts can locate the PostgreSQL and Redis containers, run the databases in Docker and start the Spring Boot services locally:

### 1. Start PostgreSQL and Redis (Docker)
In your workspace root, start the database and cache containers:
```powershell
docker compose up -d
```
*This launches containers named `mission5-postgres` and `mission5-redis` (as required by the testing scripts).*

### 2. Start the Spring Boot Applications (Local JVM)
Open two separate terminal windows/tabs:
- **Terminal 1 (Central Service - Server 03)**:
  ```powershell
  cd central-service
  ./mvnw spring-boot:run
  ```
  *(Runs on port 8081)*
- **Terminal 2 (Web Admin App - Server 01)**:
  ```powershell
  cd web-admin-app
  ./mvnw spring-boot:run
  ```
  *(Runs on port 8080)*

---

## Part 2: Required Screenshots and How to Get Them

### 📸 Screenshot 1: End-to-End Flow Verification (`verify-flow.ps1`)
This script checks if adding a product via Central Service updates the database, updates the Redis cache, displays it on the homepage, and deletes it cleanly afterwards.

**Steps to run**:
In PowerShell, run:
```powershell
./db/verify-flow.ps1
```
**What to capture**:
- Take a screenshot of the PowerShell terminal showing:
  - `Homepage is UP! Status Code: 200`
  - `Product successfully created in PostgreSQL!`
  - `SUCCESS: Redis cache has been updated and contains 'Quantum Mouse'!`
  - `SUCCESS: Homepage displays 'Quantum Mouse' successfully!`
  - `VERIFICATION TEST COMPLETED SUCCESSFULLY`

---

### 📸 Screenshot 2 & 3: Database Indexing Performance (Before vs. After)
This test proves how indexing improves query performance, which is a key grading rubric. The `benchmark.ps1` script runs queries on `10,000` seeded product records, creates database indexes, and logs the execution plans.

**Steps to run**:
In PowerShell, run:
```powershell
./db/benchmark.ps1
```
This script updates two text files: `db/benchmark_before.txt` and `db/benchmark_after.txt`.

**What to capture**:
- **Before Indexing Screenshot**: Open `db/benchmark_before.txt` and take a screenshot showing the `Seq Scan` (Sequential Scan) on the `products` table and the execution time (e.g., `~1.8 ms`).
- **After Indexing Screenshot**: Open `db/benchmark_after.txt` and take a screenshot showing the `Index Scan` (using `idx_products_category` or `idx_products_name`) and the execution time reduction (e.g., `~0.05 ms`, showing a 30x+ performance boost!).

---

### 📸 Screenshot 4 & 5: pgBadger Database Monitoring Reports
The benchmark script automatically runs a load of 500 search queries, extracts the PostgreSQL activity logs, and runs pgBadger to compile an HTML dashboard.

**Steps to view**:
1. Open file Explorer and go to the project directory: `db/`
2. Double-click the file `db/report.html` to open it in your browser.
*(If you need to regenerate it, run `./db/run-pgbadger.ps1` in PowerShell)*

**What to capture**:
- **Screenshot 4 (Overview Dashboard)**: Capture the main dashboard showing total queries, database activity graphs, and peak traffic periods.
- **Screenshot 5 (Query Details)**: Scroll down to the **"Top slow queries"** or **"Most frequent queries"** table to show that pgBadger successfully analyzes PostgreSQL queries.

---

### 📸 Screenshot 6: Redis Cache Verification (Server 02)
You must prove to the instructor that the homepage retrieves data from Redis and that data is actually stored inside the Redis database.

**Steps to run**:
Inspect the Redis keys and cached products via terminal command:
```powershell
# List all keys inside the Redis cache container
docker exec -it mission5-redis redis-cli keys "*"

# Get the cached products catalog JSON
docker exec -it mission5-redis redis-cli get products:all
```
**What to capture**:
- A screenshot of the terminal output showing the key `products:all` and the JSON string representing your database's product records.

---

### 📸 Screenshot 7: PostgreSQL Database Schema & Indexes (Server 04)
You need to show your database table definitions and prove that the B-Tree indexes were created successfully.

**Steps to run**:
Run the following command to display the schema and indexes of the `products` table:
```powershell
docker exec -it mission5-postgres psql -U postgres -d mission5_db -c "\d products"
```
**What to capture**:
- The output table showing columns (`id`, `category_id`, `name`, `description`, `price`, `created_at`) and the section labeled **"Indexes:"** showing:
  - `idx_products_category` btree (category_id)
  - `idx_products_name` btree (name)
  - `idx_products_created_at` btree (created_at)

---

### 📸 Screenshot 8 & 9: Web Application & Admin UI (Server 01)
Prove your user interfaces are active and functional.

**Steps to capture**:
1. **Homepage** (`http://localhost:8080/`):
   - Capture the landing page. Point out the indicator labeled **"Data Delivery Mode: Redis Cache"** and **"Cache Server Status: Redis Cache"** to prove the homepage retrieved data from Redis.
2. **Admin Panel** (`http://localhost:8080/admin`):
   - Fill out the form to add a new product.
   - Click the **"Save Product"** button.
   - Capture the screen showing the green flash success banner: `"Product saved successfully! Database and cache updated."`
   - Capture the **"Sync/Refresh Redis Cache"** button which triggers a manual cache reload.

---

## Part 3: Architecture & Grading Requirements Checklist

Here is how your codebase directly satisfies the grading requirements:

| Grading Requirement | How Code Implements It | Code File / Proof |
| :--- | :--- | :--- |
| **Homepage uses Redis** | `HomepageController` *only* calls `RedisCacheService`, never the PostgreSQL repo. | [HomepageController.java](file:///c:/Users/tojit/OneDrive/Documents/School%20Projects/Mission-5/web-admin-app/src/main/java/com/example/web_admin_app/controller/HomepageController.java#L24-L25) |
| **Admin Panel update flow** | Admin saves a product -> calls Central Service REST API -> updates DB -> clears/updates Redis cache. | [AdminController.java](file:///c:/Users/tojit/OneDrive/Documents/School%20Projects/Mission-5/web-admin-app/src/main/java/com/example/web_admin_app/controller/AdminController.java#L36-L60) |
| **Central Service** | Exposes REST endpoints to save/delete and manually refresh Redis cache from PostgreSQL. | [ProductController.java](file:///c:/Users/tojit/OneDrive/Documents/School%20Projects/Mission-5/central-service/src/main/java/com/example/central_service/controller/ProductController.java) |
| **PostgreSQL & Indexing** | Permanent schema is set in `db/init.sql`. Indexes are built by `benchmark.ps1`. | [init.sql](file:///c:/Users/tojit/OneDrive/Documents/School%20Projects/Mission-5/db/init.sql) & [benchmark.ps1](file:///c:/Users/tojit/OneDrive/Documents/School%20Projects/Mission-5/db/benchmark.ps1#L55-L68) |
| **pgBadger Reports** | PostgreSQL is configured with logging parameters (log prefix, collector, etc.), and reports are built with pgBadger. | [postgresql.conf](file:///c:/Users/tojit/OneDrive/Documents/School%20Projects/Mission-5/db/postgresql.conf) & [run-pgbadger.ps1](file:///c:/Users/tojit/OneDrive/Documents/School%20Projects/Mission-5/db/run-pgbadger.ps1) |

---

## Part 4: Testing on a Deployed Droplet

If you want to perform validation directly on your live DigitalOcean Droplet, follow these steps via SSH.

### 1. Access Your Droplet Terminal
Establish an SSH connection from your local computer:
```bash
ssh root@<your_droplet_ip>
```

### 2. Verify Redis Cache (Server 02)
Run Redis CLI commands directly inside the live production container:
```bash
# Check existing cache keys
docker exec -it mission5-redis-prod redis-cli keys "*"

# Print the cached product list JSON
docker exec -it mission5-redis-prod redis-cli get products:all
```

### 3. Verify Postgres Schema & Indexes (Server 04)
Run database console commands inside the live Postgres container:
```bash
docker exec -it mission5-postgres-prod psql -U postgres -d mission5_db -c "\d products"
```

### 4. Run SQL Performance Indexing Benchmark
Run EXPLAIN ANALYZE queries directly in the database container to compare query performance with and without indexes:
```bash
# Test query performance on category_id
docker exec -it mission5-postgres-prod psql -U postgres -d mission5_db -c "EXPLAIN ANALYZE SELECT * FROM products WHERE category_id = 3;"
```

### 5. Generate and Download pgBadger Reports on the Droplet
To extract Postgres activity logs on the Droplet and generate the HTML report:

1. **Extract logs and generate HTML**:
   ```bash
   # Copy postgresql.log from the container
   docker cp mission5-postgres-prod:/var/lib/postgresql/data/log/postgresql.log /opt/mission-5/db/postgresql.log

   # Run pgBadger via a temporary Docker image to generate report.html
   docker run --rm -v "/opt/mission-5/db:/data" alpine sh -c "apk add --no-cache perl wget && wget -q https://raw.githubusercontent.com/darold/pgbadger/master/pgbadger -O /usr/local/bin/pgbadger && chmod +x /usr/local/bin/pgbadger && pgbadger /data/postgresql.log -o /data/report.html"
   ```
2. **Download the report to your local PC**:
   Open a **new terminal tab on your local PC** (not SSH) and run:
   ```bash
   scp root@<your_droplet_ip>:/opt/mission-5/db/report.html ./db/report_droplet.html
   ```
   You can now open `report_droplet.html` locally in any web browser to capture your screenshots!

