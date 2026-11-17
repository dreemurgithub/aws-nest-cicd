# AWS Nest CI/CD starter

A small NestJS API for validating a GitHub Actions deployment to an AWS host. It uses PostgreSQL through TypeORM and Redis/BullMQ for background work.

## What it does

`POST /tasks` creates a database record and adds a `process-task` job to BullMQ. The in-process worker immediately marks that task as `completed`.

```sh
curl -X POST http://localhost:3000/tasks \
  -H 'content-type: application/json' \
  -d '{"message":"hello from the queue"}'
```

## Start with a normal PostgreSQL service

Create a PostgreSQL database and role using your local PostgreSQL installation or a managed database service:

```sql
CREATE USER app WITH PASSWORD 'app';
CREATE DATABASE app OWNER app;
```

Ensure Redis is available at the `REDIS_HOST` and `REDIS_PORT` in your environment file. This can be a normally installed Redis service or a managed Redis instance.

## Local start

```sh
cp .env.example .env
npm install
npm run migration:run
npm run start:dev
```

## Deployment

Pushes to `main` execute `.github/workflows/deploy.yml`. Before the first deploy, prepare the server:

```sh
git clone <repository-url> /srv/aws-nest-cicd
cd /srv/aws-nest-cicd
sudo ./script/setup-package.sh
```

`setup-package.sh` supports Ubuntu/Debian and installs PostgreSQL, Node.js/npm,
and PM2. It creates the local PostgreSQL database below (the name is lowercase
for PostgreSQL), and is safe to re-run:

```dotenv
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=awsnestcicd
DATABASE_USER=postgres
DATABASE_PASSWORD=password
```

Then copy `.env.example` to `.env` and set the database values above along with
your Redis settings.

After DNS for your domain points to the server and Nginx has that domain in its
`server_name`, install a Let's Encrypt certificate:

```sh
sudo ./script/cert.sh api.example.com admin@example.com
```

For a certificate covering multiple names, provide the extra names after the
email address. The script installs Certbot from Snap, configures Nginx to
redirect HTTP to HTTPS, and verifies automatic renewal with a dry run.

Set these GitHub Actions secrets:

| Secret | Value |
| --- | --- |
| `SSH_HOST` | Server hostname or IP |
| `SSH_USER` | SSH login user |
| `SSH_PRIVATE_KEY` | Private key permitted on the server |
| `SSH_PORT` | SSH port (optional; defaults to 22) |
| `DEPLOY_PATH` | Absolute checkout path, e.g. `/srv/aws-nest-cicd` |

The `.env` lives only on the server and is deliberately not created or overwritten by CI. The deployment installs dependencies, runs pending migrations, builds, and reloads PM2.
