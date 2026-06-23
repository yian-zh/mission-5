# DigitalOcean Deployment Guide - Mission 5

This guide provides step-by-step instructions for deploying the Mission-5 multi-service stack on DigitalOcean. The project consists of:
- **`postgres`**: Database service (PostgreSQL 15)
- **`redis`**: Caching service (Redis 7)
- **`central-service`**: Spring Boot backend application (Java 21, Port 8081)
- **`web-admin-app`**: Spring Boot front-end admin application (Java 21 + Thymeleaf, Port 8080)

We outline two deployment pathways:
1. **Option A: DigitalOcean Droplet (Docker Compose)** — Cost-effective, customizable, and matches the local Docker setup. (Recommended for testing and school projects).
2. **Option B: DigitalOcean App Platform (Managed PaaS)** — Fully managed, highly scalable, and handles SSL, deployments, and managed databases automatically.

---

## Option A: DigitalOcean Droplet (Docker Compose)

This approach uses a single virtual machine (Droplet) to host all services using the custom [docker-compose.prod.yml](file:///c:/Users/tojit/OneDrive/Documents/School%20Projects/Mission-5/docker-compose.prod.yml).

### Step 1: Provision a Droplet
1. Log in to the **DigitalOcean Control Panel**.
2. Click **Create** (top right) -> **Droplets**.
3. **Choose Region**: Select a region close to your target audience.
4. **Choose Image**: Select **Ubuntu 24.04 LTS (x64)**.
5. **Choose Size**: Select **Basic** CPU. Under CPU Options, choose **Regular** and select the **$6/month** (1 GB RAM, 1 vCPU, 25 GB SSD) or **$12/month** (2 GB RAM, 1 vCPU, 50 GB SSD) option.
   - *Note: Since we are running two Spring Boot JVM instances, 2 GB RAM is highly recommended for optimal performance during Maven builds.*
6. **Authentication**: Choose **SSH Keys** (create one if you don't have one) for secure access.
7. Click **Create Droplet**. Note the public IP address once the Droplet is running.

### Step 2: Configure the Firewall (UFW)
For security, we block direct access to database ports and only allow SSH, HTTP, and HTTPS traffic.

Connect to your Droplet via SSH:
```bash
ssh root@your_droplet_ip
```

Configure the Uncomplicated Firewall (UFW):
```bash
# Allow SSH
ufw allow OpenSSH

# Allow HTTP and HTTPS (for Nginx reverse proxy)
ufw allow 80/tcp
ufw allow 443/tcp

# Enable Firewall
ufw enable
```

### Step 3: Install Docker & Docker Compose
Execute the following commands on the Droplet to install Docker:
```bash
# Update package database
apt-get update

# Install prerequisites
apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Verify the installation:
```bash
docker --version
docker compose version
```

### Step 4: Clone Code and Launch Stack
1. Clone your project repository onto the Droplet:
   ```bash
   git clone <your-repository-url> /opt/mission-5
   cd /opt/mission-5
   ```
2. Start the production stack:
   ```bash
   docker compose -f docker-compose.prod.yml up -d --build
   ```
3. Check the running containers:
   ```bash
   docker compose -f docker-compose.prod.yml ps
   ```

### Step 5: Reverse Proxy with Nginx & SSL Setup
To map custom domain names and serve traffic securely over HTTPS, configure Nginx as a reverse proxy.

1. **Install Nginx**:
   ```bash
   apt-get install -y nginx
   ```
2. **Create Configuration**:
   Create a virtual host configuration file for Nginx:
   ```bash
   nano /etc/nginx/sites-available/mission5
   ```
   Add the following configuration (replace `yourdomain.com` with your actual domain or use Droplet's IP temporarily):
   ```nginx
   server {
       listen 80;
       server_name yourdomain.com www.yourdomain.com;

       # Route to Web Admin Front-end
       location / {
           proxy_pass http://localhost:8080;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }

       # Route to Central Service API
       location /api {
           proxy_pass http://localhost:8081;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```
3. **Enable Site & Restart Nginx**:
   ```bash
   ln -s /etc/nginx/sites-available/mission5 /etc/nginx/sites-enabled/
   rm /etc/nginx/sites-enabled/default
   nginx -t
   systemctl restart nginx
   ```
4. **Acquire SSL Certificate via Let's Encrypt**:
   ```bash
   apt-get install -y certbot python3-certbot-nginx
   certbot --nginx -d yourdomain.com -d www.yourdomain.com
   ```
   Follow the prompts to enable redirecting HTTP traffic to HTTPS.

---

## Option B: DigitalOcean App Platform (PaaS)

If you prefer not to manage virtual servers, SSH keys, or Docker installation, use DigitalOcean App Platform. This method deploys the stack directly from GitHub and utilizes managed database components.

### Step 1: Provision Managed Databases
To run Spring Boot securely in a serverless format, create dedicated managed databases:

1. **PostgreSQL**:
   - Go to **Databases** -> **Create Database Cluster**.
   - Choose **PostgreSQL** (version 15).
   - Select **Development Database** (single node, $15/month) or high-tier for production.
   - Choose a cluster name (e.g., `mission5-db-prod`).
   - Once provisioned, note the connection details (Host, Database, User, Password, Port).
   - *Important*: Go to **Users & Databases** and ensure the database name matches `mission5_db` (or update it in your app properties).
2. **Redis**:
   - Go to **Databases** -> **Create Database Cluster**.
   - Choose **Redis** (version 7).
   - Choose a cluster name (e.g., `mission5-redis-prod`).
   - Once provisioned, note the connection details (specifically Host, Port, and Password).

### Step 2: Create App Platform Application
1. Go to **Apps** -> **Create App**.
2. Select **GitHub** as the source repository and authorize DigitalOcean.
3. Select your repository and the deployment branch (e.g., `main`).
4. Click **Next**.

### Step 3: Configure Components
DigitalOcean will analyze your repository and detect components. Since the project has two maven root folders, we will define them as two distinct Web Services:

#### Component 1: `central-service`
1. **Rename** the component to `central-service`.
2. **Resource Type**: Web Service.
3. **Source Directory**: Set to `/central-service`.
4. **Buildpack**: Java/Maven (automatically detected).
5. **HTTP Port**: Set to `8081`.
6. **Environment Variables**: Add the following config:
   - `SPRING_DATASOURCE_URL` = `jdbc:postgresql://<DB_HOST>:<DB_PORT>/mission5_db?sslmode=require`
   - `SPRING_DATASOURCE_USERNAME` = `<DB_USER>`
   - `SPRING_DATASOURCE_PASSWORD` = `<DB_PASSWORD>`
   - `SPRING_DATA_REDIS_HOST` = `<REDIS_HOST>`
   - `SPRING_DATA_REDIS_PORT` = `<REDIS_PORT>`
   - `SPRING_DATA_REDIS_PASSWORD` = `<REDIS_PASSWORD>`

#### Component 2: `web-admin-app`
1. **Rename** the component to `web-admin-app`.
2. **Resource Type**: Web Service.
3. **Source Directory**: Set to `/web-admin-app`.
4. **Buildpack**: Java/Maven (automatically detected).
5. **HTTP Port**: Set to `8080`.
6. **Environment Variables**: Add the following config:
   - `SPRING_DATA_REDIS_HOST` = `<REDIS_HOST>`
   - `SPRING_DATA_REDIS_PORT` = `<REDIS_PORT>`
   - `SPRING_DATA_REDIS_PASSWORD` = `<REDIS_PASSWORD>`
   - `CENTRAL_SERVICE_URL` = `http://localhost:8081/api` (If internal communication is routed locally within the app network) or the public URL of `central-service`.
     - *Note: App Platform allows linking services using their internal name. Use `http://central-service:8081/api` inside the App Platform environment if they share the same App specification.*

### Step 4: Routing & Domains
- Under **Routes**, map `/` to the `web-admin-app` component.
- Under **Routes**, map `/api` to the `central-service` component.
- App Platform will generate a secure `https://...ondigitalocean.app` domain automatically. You can map custom domains under the App's **Settings** tab.

---

## Appendix: Database Migrations and Seeding

When deploying to a fresh database (either Droplet Postgres or Managed PostgreSQL), the schema must be initialized:

1. **Spring Boot Auto-DDL**: Both services are configured with `spring.jpa.hibernate.ddl-auto=update` in `central-service`, which automatically creates tables on startup.
2. **Seeding Initial Data**:
   To seed categories and products, run the SQL script located at `db/init.sql` against the database.
   - **For Droplet**:
     Enter the postgres container and run the script:
     ```bash
     docker exec -i mission5-postgres-prod psql -U postgres -d mission5_db < db/init.sql
     ```
   - **For Managed Databases**:
     Use a client command line tool (like `psql`) to connect using the connection string and pipe the SQL file:
     ```bash
     psql "postgresql://user:password@managed-db-host:port/mission5_db?sslmode=require" -f db/init.sql
     ```

---

## Log Analysis and Monitoring (pgBadger)
If you are deploying using the **Droplet** option, you can easily use the custom log setup configuration.
The project is configured to write logs matching pgBadger parameters to `/etc/postgresql/postgresql.conf` which is volume-mounted inside the container.
- To view container logs:
  ```bash
  docker compose -f docker-compose.prod.yml logs -f postgres
  ```
- To run pgBadger reports on the log files on the droplet, utilize the helper script:
  ```bash
  ./db/run-pgbadger.ps1
  ```
