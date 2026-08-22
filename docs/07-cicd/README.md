# Stage 7: CI/CD Pipeline (Planned)

## Goal
GitLab + Jenkins Pipeline: code commit → build → test → deploy to K8s.

## Planned pipeline
```
Developer push → GitLab webhook → Jenkins pipeline:
  1. Checkout code
  2. Build Docker image (multi-stage)
  3. Run unit tests
  4. Push to Harbor registry
  5. kubectl apply to K8s (rolling update)
  6. Smoke test (curl 200 + keyword)
  7. Feishu notification (success/failure)
```

## Jenkinsfile evolution
- v1: Freestyle project (manual)
- v2: Scripted Pipeline
- v3: Declarative Pipeline with stages
- v4: Multibranch Pipeline (auto-trigger on PR)

## Interview points
- Pipeline as code: Jenkinsfile in repo
- Blue-green deployment: zero downtime
- Rollback: `kubectl rollout undo`
- Webhook: push-triggered, not polling

## Key files
- `cicd/Jenkinsfile` — declarative pipeline
