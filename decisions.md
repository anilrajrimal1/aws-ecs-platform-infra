# Design Decisions and Tradeoffs

## Terragrunt over raw Terraform

**Decision:** Use Terragrunt as the orchestration layer.

**Reasoning:** The infrastructure has 14+ distinct modules across multiple environments. Without Terragrunt, each module needs its own backend configuration copy and the provider block must be repeated everywhere. Terragrunt's `include` and `generate` blocks keep this DRY. The `dependency` block provides a typed, validated way to pass outputs between modules without using data sources, which would require the dependent state to already exist at plan time.

**Tradeoff:** Adds a build-time dependency and a learning curve. Terragrunt's HCL is not standard Terraform and requires its own documentation. The `.terragrunt-cache` directory can grow large and should be excluded from version control.

## Purgeable vs non-purgeable split

**Decision:** Group modules into two categories based on whether they hold state that survives environment teardown.

**Reasoning:** In a development environment, ECS services can be stopped at end of day to reduce compute cost. The underlying network, database, and storage must remain. Codifying this split in the folder structure makes it impossible to accidentally destroy a database when tearing down application services.

**Tradeoff:** Requires discipline to keep the split accurate as the architecture evolves. A Redis cache cluster is purgeable in theory but placed in non-purgeable here because recreating it requires flushing warmed-up cached data.

## Aurora Serverless v2 over provisioned RDS

**Decision:** Use Aurora Serverless v2 instead of a fixed instance class.

**Reasoning:** The dev environment has irregular traffic. Serverless v2 scales ACUs in sub-second intervals without connection disruption. The minimum capacity of 24 ACUs is higher than necessary for a dev environment but was chosen to avoid cold-start latency during automated test runs.

**Tradeoff:** Aurora Serverless v2 costs more per ACU-hour than equivalent provisioned capacity when running at maximum scale. For a predictable production workload, a provisioned r6g instance would likely be cheaper. Serverless v2 also does not support all Aurora features (e.g., no cross-region read replicas as of Aurora PostgreSQL 15).

## Two Redis clusters

**Decision:** Provision a separate Redis cluster for session storage and one for application cache.

**Reasoning:** Sessions and cached query results have different eviction requirements. Sessions must not be evicted under memory pressure (they log users out). Cache keys can be evicted aggressively. Running them on separate clusters allows independent `maxmemory-policy` configuration without affecting each other.

**Tradeoff:** Double the management overhead and two sets of CloudWatch metrics to monitor. For a small deployment, a single cluster with key prefix namespacing and a conservative `allkeys-lru` policy is a reasonable alternative.

## EFS for shared secrets over Secrets Manager

**Decision:** Mount secrets as files on EFS rather than injecting all of them as Secrets Manager ARNs in the ECS task definition.

**Reasoning:** Some application components expect credentials as files at a known path (e.g., JSON key files for external service SDKs). Secrets Manager natively injects secrets as environment variables. Storing the JSON blob in Secrets Manager and deserialising it in an entrypoint script is possible but fragile. EFS provides a file system interface without requiring the container to understand Secrets Manager's API.

**Tradeoff:** EFS adds cost, throughput limits, and an additional dependency. EFS access points are mounted read-only to reduce the blast radius of a compromised container. Secrets stored on EFS are not rotated automatically - Secrets Manager rotation policies cannot be applied to file-based secrets.

## CloudFront in front of the ALB

**Decision:** All public traffic enters through CloudFront rather than directly hitting the ALB.

**Reasoning:** CloudFront provides geographic distribution, absorbs DDoS at the edge before traffic reaches the origin, and enables static asset caching without application changes. The ALB HTTPS listener requires the CloudFront distribution to pass a custom header (`X-Forwarded-Proto: https`) so the Django application knows the original protocol.

**Tradeoff:** CloudFront adds an additional caching layer that can cause stale content problems if cache invalidation is not triggered on deployments. CloudFront's `CachingDisabled` managed policy is used for all ALB-backed behaviors to avoid this for dynamic content. Static asset paths use `CachingOptimized`.

## Single ECS cluster

**Decision:** All ECS services share one cluster rather than using separate clusters per tier.

**Reasoning:** Fargate billing is per task, not per cluster. A shared cluster reduces the number of resources to monitor in the ECS console and simplifies CloudWatch log group naming. Services are isolated at the security group and IAM level regardless of cluster membership.

**Tradeoff:** A single cluster means the cluster name is a shared dependency. If the cluster is accidentally deleted, all services in it stop. In practice this is an acceptable risk for a development environment.

## No Redis encryption in dev

**Decision:** Redis `at_rest_encryption_enabled` and `transit_encryption_enabled` are set to `false` in the dev environment.

**Reasoning:** Dev Redis contains no production data. Enabling encryption requires ElastiCache to use a replication group (not a single node), which changes the Redis endpoint format and requires application configuration changes. Deferring this to the staging environment configuration reduces dev setup friction.

**Tradeoff:** This must not be replicated to staging or production. The decision should be revisited when adding staging configuration and the staging module should have both flags set to `true`.

## EC2 bastion over SSM Session Manager only

**Decision:** Provision an EC2 instance with IAM permissions for deployment tasks rather than relying solely on ECS exec.

**Reasoning:** Deployment workflows (building container images, pushing to ECR, triggering ECS service updates) require sustained compute. ECS exec is designed for ephemeral container debugging, not multi-minute build jobs. The bastion provides a stable execution environment with Docker installed and AWS credentials available via the instance profile.

**Tradeoff:** The bastion is an attack surface. It is placed in a public subnet with a generated SSH key pair. The instance should be hardened (disable password auth, restrict security group ingress to known CIDR blocks) before being used in a production-adjacent environment.

## Bitbucket Pipelines for CI/CD

**Decision:** Use Bitbucket Pipelines with a custom pipeline (manual trigger) rather than an automatic on-push pipeline.

**Reasoning:** Infrastructure changes must be reviewed before applying. The two-step plan-then-apply pattern with a manual gate between them mirrors the `terraform plan` review workflow that most teams use. Destroying infrastructure is a separate pipeline with its own confirmation step.

**Tradeoff:** Pipelines are tightly coupled to Bitbucket. Migrating to GitHub would require rewriting the pipeline configuration. For a public portfolio project, GitHub Actions would be a better choice for visibility.
