# Djodolist — Django To-Do Web Application

A task management web application built with Django and Django REST Framework, backed by MySQL. The application itself is straightforward — the main focus of this project is the infrastructure layer: containerization, Kubernetes orchestration, Helm packaging, and an automated CI/CD pipeline.

---

## Tech Stack

| Layer | Tools |
|---|---|
| Application | Python 3.9, Django 4.1, Django REST Framework, MySQL 8.0 |
| Containerization | Docker (multi-stage builds), Docker Compose |
| Orchestration | Kubernetes, Helm |
| CI/CD | GitHub Actions |
| Local K8s | Kind (Kubernetes in Docker) |

---

## Architecture

The application follows a two-tier architecture:

- **Backend** — Django app serving the web UI and REST API. Exposes `/api/health` and `/api/ready` endpoints for Kubernetes liveness and readiness probes.
- **Database** — MySQL 8.0 with a Persistent Volume to ensure data integrity across pod restarts.

---

## Deployment Options

### Option 1 — Docker Compose (local development)

The fastest way to run the app locally without any Kubernetes setup.

```bash
cp .env-example .env        # configure DB credentials if needed
docker-compose up --build
```

The app will be available at `http://localhost:8080`. Django migrations run automatically via `entrypoint.sh`.

---

### Option 2 — Automated local K8s via `bootstrap.sh`

Spins up a full local Kubernetes environment from scratch. Requires Docker, `kind`, and `kubectl`.

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

The script does the following:

1. Creates a multi-node Kind cluster from `cluster.yml` — 1 control-plane node and 6 worker nodes, with ports 80 and 443 mapped to the host
2. Installs the NGINX Ingress Controller
3. Creates namespaces for the app and database components
4. Applies all manifests from `.infrastructure/` — MySQL StatefulSet, ConfigMaps, Secrets, RBAC resources, Services, and the app Deployment

Once complete, the application is reachable through the local Ingress proxy.

---

### Option 3 — Helm (production-like deployment)

The most production-representative option. Uses Helm as a Kubernetes package manager for versioned, parameterized deployments.

```bash
cd .infrastructure/helm-chart

# Validate the chart before deploying
helm lint todoapp
helm template todoapp ./todoapp

# Deploy with default values from values.yaml
helm install djodolist ./todoapp

# Override specific values at install time
helm install djodolist ./todoapp --set replicaCount=3 --set mysql.replicaCount=2

# Upgrade or remove
helm upgrade djodolist ./todoapp
helm uninstall djodolist
```

---

## Kubernetes Features

**Stateful storage**
MySQL runs as a StatefulSet with a PersistentVolumeClaim (`storageClassName: standard`), ensuring data survives pod restarts.

**Autoscaling**
A HorizontalPodAutoscaler scales the app between 2 and 5 replicas based on CPU and memory utilization, with a 70% target threshold.

**High availability**
`podAntiAffinity` rules distribute app and database pods across different nodes, preventing a single node failure from taking down the entire application.

**RBAC**
The app runs under a dedicated ServiceAccount bound to a Role that grants read-only access to the specific Secrets it requires — nothing broader.

---

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/main.yml`) runs three jobs on every push:

**Python CI**
- Code linting with `flake8`, including cyclomatic complexity checks
- Unit tests with code coverage reporting

**Docker CI**
- Multi-stage image build running as a non-root user
- Automatic push to Docker Hub tagged with the commit SHA

**Helm CI**
- Chart validation with `helm lint`
- Chart packaged into a `.tgz` artifact for release