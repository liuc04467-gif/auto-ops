# Stage 5: Containerization (Planned)

## Goal
Containerize the web application, set up Harbor private registry.

## Planned steps
1. Write multi-stage Dockerfile for PHP app
2. Optimize image layers (target: <200MB from 800MB)
3. Deploy Harbor on monitor (or dedicated VM)
4. Docker Compose for multi-container local dev
5. Push images to Harbor, pull on web nodes

## Interview points
- Multi-stage build: builder stage compiles, runtime stage is slim
- Layer caching: COPY requirements first, install deps, then COPY app code
- Image scanning: Trivy for CVE detection
- Harbor: replication, vulnerability scanning, RBAC

## Key files
- `docker/Dockerfile` — multi-stage PHP build
- `docker/docker-compose.yml` — local development stack
