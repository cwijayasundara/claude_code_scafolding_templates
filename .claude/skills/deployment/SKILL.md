---
name: deployment
description: Docker multi-stage builds, Azure App Service deployment, deployment slots, environment variable management, health checks, and rollback strategy
disable-model-invocation: true
---

# Skill: Deployment

## When to Use
Apply this skill when building Docker images, configuring Azure App Service, managing environments, or handling rollbacks.

## Docker Multi-Stage Build
```dockerfile
# Stage 1: Builder
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Production
FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /install /usr/local
COPY src/ ./src/
RUN useradd --create-home appuser
USER appuser
EXPOSE 8000
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Docker Best Practices
- Use slim base images
- Non-root user in production
- Copy only what's needed (no tests, docs, dev deps)
- Pin base image versions
- Use `.dockerignore` to exclude unnecessary files

## Azure App Service Deployment

### Backend (Python/FastAPI Agent)
```bash
# Build and push to Azure Container Registry (ACR)
az acr build --registry $ACR_NAME --image $SERVICE:$TAG .

# Create App Service Plan (Linux, container-based)
az appservice plan create \
  --name $PLAN_NAME \
  --resource-group $RESOURCE_GROUP \
  --is-linux --sku P1v3

# Create Web App with container image
az webapp create \
  --name $SERVICE \
  --resource-group $RESOURCE_GROUP \
  --plan $PLAN_NAME \
  --deployment-container-image-name $ACR_NAME.azurecr.io/$SERVICE:$TAG

# Configure app settings (environment variables)
az webapp config appsettings set --name $SERVICE \
  --resource-group $RESOURCE_GROUP \
  --settings APP_ENV=production DATABASE_URL=$DB_URL

# Deploy to staging slot
az webapp deployment slot create --name $SERVICE \
  --resource-group $RESOURCE_GROUP --slot staging

az webapp config container set --name $SERVICE \
  --resource-group $RESOURCE_GROUP --slot staging \
  --image $ACR_NAME.azurecr.io/$SERVICE:$TAG

az webapp config appsettings set --name $SERVICE \
  --resource-group $RESOURCE_GROUP --slot staging \
  --settings APP_ENV=staging DATABASE_URL=$STAGING_DB_URL
```

### Frontend (React App)
```bash
# Create Web App for static React build
az webapp create \
  --name $FRONTEND_SERVICE \
  --resource-group $RESOURCE_GROUP \
  --plan $PLAN_NAME \
  --runtime "NODE:20-lts"

# Deploy React build using zip deploy
cd frontend && npm run build
zip -r build.zip dist/
az webapp deploy --name $FRONTEND_SERVICE \
  --resource-group $RESOURCE_GROUP \
  --src-path build.zip --type zip

# Configure startup command for SPA routing
az webapp config set --name $FRONTEND_SERVICE \
  --resource-group $RESOURCE_GROUP \
  --startup-file "pm2 serve /home/site/wwwroot/dist --no-daemon --spa"
```

### Enable Continuous Deployment from ACR
```bash
# Enable CI/CD webhook for automatic deploys when image is pushed
az webapp deployment container config --enable-cd true \
  --name $SERVICE --resource-group $RESOURCE_GROUP

# Configure ACR credentials
az webapp config container set --name $SERVICE \
  --resource-group $RESOURCE_GROUP \
  --container-registry-url https://$ACR_NAME.azurecr.io \
  --container-registry-user $ACR_USERNAME \
  --container-registry-password $ACR_PASSWORD
```

## Deployment Slots (Staging + Production)

App Service deployment slots enable zero-downtime deployments:

```bash
# Deploy new version to staging slot
az webapp config container set --name $SERVICE \
  --resource-group $RESOURCE_GROUP --slot staging \
  --image $ACR_NAME.azurecr.io/$SERVICE:$NEW_TAG

# Wait for staging to be healthy
az webapp show --name $SERVICE \
  --resource-group $RESOURCE_GROUP --slot staging \
  --query "state" -o tsv

# Run smoke tests against staging slot
curl -f https://$SERVICE-staging.azurewebsites.net/health

# Swap staging → production (zero downtime)
az webapp deployment slot swap --name $SERVICE \
  --resource-group $RESOURCE_GROUP \
  --slot staging --target-slot production
```

**Slot-specific settings** (not swapped during slot swap):
- `DATABASE_URL` — each slot connects to its own database
- `APP_ENV` — staging vs production
- `APPLICATIONINSIGHTS_CONNECTION_STRING` — separate telemetry per slot

Mark settings as slot-specific:
```bash
az webapp config appsettings set --name $SERVICE \
  --resource-group $RESOURCE_GROUP \
  --slot-settings DATABASE_URL APP_ENV
```

## Environment Variable Management
- All configuration via environment variables (12-factor app)
- Use Pydantic Settings to load and validate env vars
- Required vars: `DATABASE_URL`, `SECRET_KEY`, `APP_ENV`
- Never hardcode URLs, credentials, or environment-specific values
- Use Azure Key Vault for sensitive values in production:
  ```bash
  # Store secret in Key Vault
  az keyvault secret set --vault-name $VAULT_NAME \
    --name database-url --value "$PROD_DB_URL"

  # Reference Key Vault secrets from App Service
  az webapp config appsettings set --name $SERVICE \
    --resource-group $RESOURCE_GROUP \
    --settings "DATABASE_URL=@Microsoft.KeyVault(VaultName=$VAULT_NAME;SecretName=database-url)"
  ```
- Enable Managed Identity for Key Vault access (no credentials needed):
  ```bash
  az webapp identity assign --name $SERVICE --resource-group $RESOURCE_GROUP
  az keyvault set-policy --name $VAULT_NAME \
    --object-id $(az webapp identity show --name $SERVICE -g $RESOURCE_GROUP --query principalId -o tsv) \
    --secret-permissions get list
  ```

## Health Checks
Every service must expose:
- `GET /health` — returns `{"status": "healthy", "version": "..."}`
- Azure App Service uses this for health check probes
- Include DB connectivity check in health response
- Health endpoint must respond in <100ms
- Configure health check in App Service:
  ```bash
  az webapp config set --name $SERVICE \
    --resource-group $RESOURCE_GROUP \
    --generic-configurations '{"healthCheckPath": "/health"}'
  ```
- App Service automatically removes unhealthy instances from load balancer rotation

## Rollback Strategy
```bash
# Swap back (production → staging) to rollback
az webapp deployment slot swap --name $SERVICE \
  --resource-group $RESOURCE_GROUP \
  --slot staging --target-slot production

# Or revert to a previous Docker image
az webapp config container set --name $SERVICE \
  --resource-group $RESOURCE_GROUP \
  --image $ACR_NAME.azurecr.io/$SERVICE:$PREVIOUS_TAG

# View deployment logs
az webapp log deployment show --name $SERVICE --resource-group $RESOURCE_GROUP
```

### When to Rollback
- Production smoke tests fail after deploy
- Error rate exceeds 5% (monitored via Azure Monitor / Application Insights)
- P95 latency exceeds 2x the baseline
- Any critical path is broken

## Scaling

```bash
# Scale up (bigger instance)
az appservice plan update --name $PLAN_NAME \
  --resource-group $RESOURCE_GROUP --sku P2v3

# Scale out (more instances) — manual
az webapp scale --name $SERVICE \
  --resource-group $RESOURCE_GROUP --instance-count 3

# Scale out (auto-scale based on CPU)
az monitor autoscale create --name $SERVICE-autoscale \
  --resource-group $RESOURCE_GROUP \
  --resource $SERVICE --resource-type Microsoft.Web/sites \
  --min-count 1 --max-count 10 --count 2

az monitor autoscale rule create --autoscale-name $SERVICE-autoscale \
  --resource-group $RESOURCE_GROUP \
  --condition "CpuPercentage > 70 avg 5m" \
  --scale out 2
```

## Azure-Specific Services

| Service | Purpose | CLI |
|---------|---------|-----|
| Azure Container Registry (ACR) | Docker image storage | `az acr` |
| Azure App Service | Web app + container hosting | `az webapp` |
| Azure App Service Plan | Compute tier (shared across apps) | `az appservice plan` |
| Azure Database for PostgreSQL | Managed PostgreSQL | `az postgres flexible-server` |
| Azure Key Vault | Secrets management | `az keyvault` |
| Azure Monitor | Metrics, alerts, logs | `az monitor` |
| Azure Application Insights | APM & distributed tracing | (auto-instrumented) |
| Azure Service Bus | Message queuing | `az servicebus` |

## Post-Deployment Verification
1. Smoke tests: health check + critical path endpoints on staging slot
2. E2E tests: full user journeys on staging slot
3. Contract tests: OpenAPI compliance (Schemathesis)
4. Performance tests: load test with Locust, verify p95 < 500ms
5. Only swap to production after ALL staging tests pass
