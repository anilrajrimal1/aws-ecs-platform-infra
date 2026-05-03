# Architecture Reference

## Infrastructure Overview

The FormFlow platform runs on AWS using a container-first approach. All application workloads run on ECS Fargate (no EC2 instances to manage for application tier), with an Aurora Serverless v2 database that scales ACUs in response to actual load.

## Network Layer

### VPC Design

```
VPC: 10.0.0.0/16
  Public Subnets (3 AZs)  - ALB, NAT Gateways
  Private Subnets (3 AZs) - ECS tasks, RDS, Redis, EFS mount targets
```

All application containers run in private subnets. Outbound internet access for private resources (ECR image pulls, Secrets Manager API calls, etc.) flows through NAT Gateways in the public subnets.

The VPC also provisions an AWS Cloud Map private DNS namespace used for service-to-service discovery. ECS services register themselves so other containers can reach them by a stable internal hostname (e.g., `enketo.ff-dev.internal`) without going through the load balancer.

### Security Groups

Each service has its own security group. The ALB security group allows inbound 80/443 from `0.0.0.0/0`. Application service security groups only allow inbound traffic from the ALB security group on the specific container port. Worker containers have no inbound rules. Redis and RDS security groups allow inbound only from the application service security groups.

## Load Balancing

The ALB handles all inbound HTTPS traffic. TLS terminates at the ALB using an ACM certificate. HTTP (port 80) redirects to HTTPS.

Routing rules (in priority order):

| Priority | Host Header | Path Pattern | Target |
|---|---|---|---|
| 1 | app.anilrajrimal.com.np | /api/v3/* | ECS FastAPI |
| 2 | app.anilrajrimal.com.np | * | ECS Web (Django) |
| 3 | forms.anilrajrimal.com.np | /-/* | ECS Enketo |
| 4 | forms.anilrajrimal.com.np | * | ECS Forms Service |

## Content Delivery

Two CloudFront distributions sit in front of the application:

**cloudfront-app** serves `app.anilrajrimal.com.np`:
- Default behavior: routes to ALB (CachingDisabled, AllViewer request policy)
- `/assets/*` behavior: serves from S3 with CachingOptimized policy

**cloudfront-forms** serves `forms.anilrajrimal.com.np`:
- Default behavior: serves root SPA from S3 with CachingOptimized
- `/v?/*` and `/-/*` behaviors: route to ALB for API and form rendering paths

A single wildcard ACM certificate (`*.anilrajrimal.com.np`) in `us-east-1` covers both distributions.

## ECS Services

All services run on Fargate. There is one ECS cluster. Services that use the ALB register with their respective target groups.

| Service | CPU | Memory | Tasks (min/max) | Port | Notes |
|---|---|---|---|---|---|
| ecs-web | 4096 | 8192 MB | 2/4 | 8000 | Django (uwsgi), auto-scales on CPU and memory |
| ecs-fastapi | 256 | 512 MB | 1/1 | 8000 | Async API service |
| ecs-service | 512 | 1024 MB | 1/2 | 8383 | Form collection backend, EFS mount for secrets |
| ecs-enketo | 512 | 1024 MB | 1/2 | 8005 | Form rendering, EFS mount for secrets |
| ecs-worker | 2048 | 4096 MB | 1/3 | - | Celery worker (default, process_submissions, longqueue) |
| ecs-beat | 256 | 512 MB | 1/1 | - | Celery beat scheduler, always exactly 1 task |
| ecs-report-worker | 2048 | 8192 MB | 1/2 | - | Report generation, higher memory for document rendering |
| ecs-submission-worker | 2048 | 6144 MB | 1/3 | - | Submission processing pipeline |

### Auto-scaling

The web service and worker scale on CPU (threshold: 60%) and memory (threshold: 70%) using step scaling policies. Scale-up has a 60-second cooldown; scale-down has a 180-second cooldown to prevent thrashing.

Step scaling increments for the web service:

- CPU 0-10% above threshold: +1 task
- CPU 10-20% above threshold: +2 tasks
- CPU >20% above threshold: +3 tasks
- CPU >25% below threshold: -1 task

### Environment Configuration

Each ECS task loads its environment in two ways:

1. An `.env` file stored in S3 is loaded at container start via `containerDefinitions.environmentFiles`. This carries non-sensitive configuration.
2. Secrets Manager ARNs are passed as `secrets` in the task definition. ECS fetches and injects these as environment variables at task launch time. RDS credentials are stored here.

### EFS Mounts

The `ecs-service` and `ecs-enketo` containers mount an EFS access point at `/etc/secrets` in read-only mode. This provides a shared, durable location for configuration files that are too large or inconvenient to store in Secrets Manager.

## Database

Aurora PostgreSQL 15 Serverless v2. Capacity is configured per environment:

| Environment | Min ACU | Max ACU | Approximate RAM range |
|---|---|---|---|
| dev | 24 | 64 | 48 GB - 128 GB |

Key cluster parameters:

- `shared_buffers`: dynamic (`GREATEST({DBInstanceClassMemory/32768}, 2097152)`) - adapts as ACUs scale
- `effective_cache_size`: dynamic (`{DBInstanceClassMemory/16384}`)
- `work_mem`: 128 MB
- `max_connections`: 5000 (instance-level, overrides cluster default)
- `log_statement`: ddl (captures schema changes)
- `log_min_duration_statement`: 5000 ms (slow query log)

The database name and admin username are derived from `${short_name}${environment}` with hyphens replaced by underscores to satisfy PostgreSQL identifier rules.

## Caching

Two separate Redis 7.0 clusters:

| Cluster | Node type | Purpose |
|---|---|---|
| redis-main | cache.t3.medium | Primary application cache and session storage |
| redis-cache | cache.t3.micro | Secondary cache for read-heavy paths |

Both are single-node (non-clustered) in the dev environment. The maintenance window is Sunday 02:00-03:00 UTC. Auto minor version upgrade is disabled to keep upgrade timing under control.

For production, `num_node_groups > 1` (cluster mode) or `num_cache_clusters > 1` (replication group) should be enabled along with `transit_encryption_enabled` and `auth_token_enabled`.

## Object Storage

| Bucket suffix | Contents | Versioning |
|---|---|---|
| -objects | Application uploads, config files, credentials | Enabled |
| -frontend-static | Pre-built frontend HTML and assets | Disabled |
| -forms-static | Pre-built form renderer static assets | Disabled |

No public bucket policies are attached to any bucket. CloudFront accesses S3 using Origin Access Control.

## IAM

**ECS Task Execution Role**: standard AWS-managed policy for pulling images from ECR and writing CloudWatch logs.

**ECS Task Role**: scoped to allow the running container to call Secrets Manager (GetSecretValue), access specific S3 bucket ARNs (GetObject, PutObject, DeleteObject), and use ECS exec for remote shell access during debugging.

**EC2 Instance Profile**: grants the bastion host access to Secrets Manager, all three S3 buckets, ECR (pull and push), and ECS control plane actions (describe, update service, run task). This allows the bastion to act as a deployment agent.

## Remote State

State is stored in S3 with DynamoDB locking:

```
bucket: ${application}-${team}-statefiles
key:    ${environment}/${path_relative_to_include()}/terraform.tfstate
lock:   ${short_name}-locks (DynamoDB)
```

State encryption is enabled at the backend level (`encrypt = true`).
