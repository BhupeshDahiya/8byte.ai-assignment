# 8Byte AI – DevOps Assignment

## Overview

This repository demonstrates a complete DevOps workflow for deploying a containerized Node.js/Express application with PostgreSQL on AWS.

The solution covers:

- Infrastructure as Code with Terraform
- AWS VPC, public/private subnets, ALB, EC2 and RDS PostgreSQL
- Dockerized application deployment
- GitHub Actions CI/CD
- Automated unit and integration testing
- Dependency and container vulnerability scanning
- AWS Secrets Manager for database credentials
- Prometheus/Grafana monitoring
- PostgreSQL and Node Exporter metrics
- Centralized application/system/access logs using Grafana Alloy and Loki
- Production deployment approval through GitHub Environments

---

# Architecture

```text
                         Internet
                            |
                            v
                    +----------------+
                    |   Public ALB   |
                    |    Port 80     |
                    +--------+-------+
                             |
                             | TCP 3000
                             v
                  +----------------------+
                  |      App EC2         |
                  |   Private Subnet     |
                  |----------------------|
                  | Node.js Application  |
                  | Docker               |
                  | Grafana Alloy        |
                  +----+------------+----+
                       |            |
               TCP 5432|            |TCP 3100
                       |            |
                       v            v
              +---------------+   +----------------------+
              | RDS PostgreSQL|   | Monitoring EC2       |
              | Private       |   | Private Subnet       |
              +---------------+   |----------------------|
                                  | Prometheus           |
                                  | Grafana               |
                                  | Loki                  |
                                  | Node Exporter         |
                                  | PostgreSQL Exporter   |
                                  +----------------------+

GitHub
  |
  v
GitHub Actions
  |
  +--> Tests
  +--> Dependency scan
  +--> Docker build
  +--> Trivy image scan
  +--> Push image to ECR
  +--> SSM deployment to EC2
  +--> Production approval
```

---

# Repository Structure

```text
.
├── .github/
│   └── workflows/
│       └── ci-cd.yml
├── crud-rest-api/
│   ├── controllers/
│   ├── models/
│   ├── routes/
│   ├── tests/
│   │   ├── unit/
│   │   └── integration/
│   ├── util/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── docker-compose.test.yml
│   ├── app.js
│   ├── index.js
│   ├── package.json
│   └── package-lock.json
├── dashboards/
│   ├── Application dash-1788451500386.json
│   └── Infra dash-1788451529518.json
├── ec2.tf
├── monitoring_ec2.tf
├── security.tf
├── rds.tf
├── ecr.tf
├── alb.tf
├── vpc.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
├── monitoring-user-data.sh
└── README.md
```

---

# Prerequisites

Install and configure:

- AWS CLI
- Terraform
- Docker
- Git
- An AWS account with permissions to create the required resources

The GitHub Actions workflow uses AWS OIDC, so long-lived AWS access keys are not required for GitHub Actions.

---

# Application

The application is a Dockerized Node.js/Express REST API backed by PostgreSQL.

Important endpoints:

```text
GET /
GET /health
GET /users
POST /users
```

Health endpoint:

```text
/health
```

is used by the Application Load Balancer.

---

# Run Locally

From the application directory:

```bash
cd crud-rest-api
```

Start the application and PostgreSQL:

```bash
docker compose up -d
```

Check:

```bash
curl http://localhost:3000/health
```

Expected:

```json
{"status":"ok"}
```

---

# Testing

The repository contains unit and integration tests.

Run the test environment:

```bash
docker compose -f docker-compose.test.yml run --rm node_app_test
```

The integration test uses an isolated PostgreSQL test database and does not connect to the deployed RDS instance.

The CI pipeline executes tests on pull requests and before deployment.

---

# Infrastructure with Terraform

Terraform creates the AWS infrastructure.

Main components:

- VPC
- Public and private subnets across two Availability Zones
- Internet Gateway
- NAT Gateway
- Application Load Balancer
- Application EC2
- Monitoring EC2
- ECR repository
- RDS PostgreSQL
- Security Groups
- IAM roles and instance profiles
- AWS Secrets Manager secret

Initialize Terraform:

```bash
terraform init
```

Format:

```bash
terraform fmt
```

Validate:

```bash
terraform validate
```

Review changes:

```bash
terraform plan
```

Apply:

```bash
terraform apply
```

Destroy when no longer required:

```bash
terraform destroy
```

Terraform state should not be committed to Git. State files, `.terraform/`, and local variable files containing secrets are excluded through `.gitignore`.

---

# AWS Network Design

The application and database run in private subnets.

The Application Load Balancer is deployed in public subnets.

Traffic flow:

```text
Internet
   |
   v
ALB :80
   |
   v
Application EC2 :3000
   |
   v
RDS PostgreSQL :5432
```

Security groups restrict communication between components.

Application EC2 is not exposed directly to the public internet.

---

# Security

## Security Groups

### ALB

Allows:

```text
0.0.0.0/0 → TCP 80
0.0.0.0/0 → TCP 443
```

The ALB can communicate with the application on TCP 3000.

### Application EC2

Allows application traffic from the ALB on TCP 3000.

Outbound access is restricted to required services such as PostgreSQL and HTTPS.

### RDS

Allows PostgreSQL traffic only from the application and monitoring security groups.

### Monitoring

Monitoring EC2 can:

- scrape application metrics on TCP 3000
- connect to PostgreSQL on TCP 5432
- receive logs from Alloy on TCP 3100

Loki is not exposed directly to the internet.

---

# Secret Management

Database credentials are stored in **AWS Secrets Manager**.

The application deployment retrieves the credentials at deployment time rather than storing database passwords in GitHub or the repository.

The EC2 IAM role is granted permission to retrieve only the required database secret.

The deployed PostgreSQL connection uses SSL.

---

# CI/CD

GitHub Actions provides the CI/CD pipeline.

Pipeline stages:

```text
Pull Request
    |
    +--> Unit Tests
    +--> Integration Tests
    +--> Dependency Audit
```

For pushes to `main`:

```text
Test
  |
  v
Build Docker Image
  |
  v
Trivy Container Scan
  |
  v
Push Image to Amazon ECR
  |
  v
Deploy Staging through AWS SSM
  |
  v
Manual Production Approval
  |
  v
Deploy Production
```

The production deployment uses a GitHub Environment with required reviewer approval.

AWS authentication from GitHub Actions uses GitHub OIDC instead of storing a static AWS access key.

---

# Vulnerability Scanning

Two vulnerability checks are included.

## Dependency scanning

The Node.js dependencies are checked using:

```bash
npm audit
```

The dependency scan is currently informational/non-blocking because the selected application contains known dependency vulnerabilities that were not practical to fully remediate within the assignment timebox.

## Container scanning

Docker images are scanned using Trivy before being pushed to ECR.

The current scan is informational/non-blocking for the same time-boxed reason.

The findings are visible in the GitHub Actions logs and are documented rather than hidden.

---

# Monitoring

Monitoring is implemented using:

- Prometheus
- Grafana
- Loki
- Grafana Alloy
- Node Exporter
- PostgreSQL Exporter

## Application metrics

The application exposes:

```text
GET /metrics
```

Metrics include:

- request count
- request rate
- HTTP error rate
- request latency
- endpoint-level request counts

## Infrastructure metrics

Node Exporter provides:

- CPU usage
- memory usage
- filesystem usage
- network traffic

## PostgreSQL metrics

PostgreSQL Exporter provides metrics such as:

- database connections
- commits
- rollbacks
- transactions
- database size
- exporter health

---

# Dashboards

Two Grafana dashboards are provided.

## Application Dashboard

Includes:

- Request rate
- Error rate
- p95 latency
- Requests by endpoint

## Infrastructure Dashboard

Includes:

- CPU
- Memory
- Disk usage
- Database connections
- Transactions/sec

The exported dashboard JSON files are stored under:

```text
dashboards/
```

They can be imported into Grafana when the monitoring EC2 is recreated.

---

# Centralized Logging

Application and access logs are written to Docker stdout.

HTTP access logging is provided by Morgan.

Grafana Alloy runs on the application EC2 and collects:

- Docker container logs
- application logs
- HTTP access logs
- system journal logs

Alloy forwards the logs to Loki on the monitoring EC2.

The resulting flow is:

```text
Application
    |
    v
Docker stdout
    |
    v
Grafana Alloy
    |
    v
Loki
    |
    v
Grafana Explore
```

Example LogQL query:

```logql
{host="app-ec2"}
```

Access log query:

```logql
{host="app-ec2"} |= "GET"
```

---

# Deployment Design

The application container is deployed using AWS Systems Manager rather than opening SSH access to the instance.

The EC2 instance has:

- SSM access
- ECR pull permissions
- Secrets Manager access

No inbound SSH port is required.

This reduces exposed network surface and allows GitHub Actions to manage deployments through SSM.

---

# Cost Considerations

This implementation intentionally uses small AWS resources to stay appropriate for a short-term assignment.

Examples include:

- `t3.small` EC2 instances
- small RDS instance
- single NAT Gateway
- limited Prometheus retention
- local Loki storage
- ECR for container images

For a production environment, cost and availability could be improved by evaluating:

- NAT Gateway alternatives
- managed monitoring
- autoscaling
- multi-AZ database configuration
- managed Kubernetes/ECS
- object storage for long-term log retention

The current design prioritizes simplicity and demonstrability within the assignment's 3-day time limit.

---

# Challenges and Resolutions

## Dependency scan fails (dependency scan)

The selected application contained multiple dependency vulnerabilities. Running npm audit as a blocking CI step would cause the pipeline to fail.

Resolution:

- The dependency vulnerability scan is kept in the pipeline as an informational check so that the findings are visible without blocking the assignment deployment. The known vulnerabilities are documented as a limitation of the selected ready-made application.

## Trivy scan fails (container scan)

The selected application container contained multiple vulnerabilities. Configuring Trivy with a failing exit code would cause the pipeline to fail.

Resolution:

- Trivy remains enabled in the pipeline, but the scan uses a non-blocking exit code so vulnerability findings are reported without preventing the assignment deployment. The findings are documented as a known limitation of the selected base application/image.

## RDS SSL connection

The application initially failed to connect to the deployed PostgreSQL instance because the RDS connection required SSL.

Resolution:

- added conditional PostgreSQL SSL configuration
- stored `PG_SSL=true` in Secrets Manager
- deployed the corrected application image

## GitHub OIDC

GitHub Actions initially could not configure AWS credentials.

Resolution:

The GitHub Actions OIDC trust policy was initially based on the legacy repository-name subject format. Because the repository was created after GitHub's immutable OIDC subject rollout, the trust policy was updated to use the GitHub owner and repository IDs.

## Monitoring bootstrap

Monitoring services needed to be bootstrapped automatically on EC2 creation.

Resolution:

- installed Docker and Docker Compose through Terraform user-data
- generated Prometheus, Loki and Grafana configuration during bootstrap
- retrieved database credentials from Secrets Manager

## Grafana dashboard size

Embedding complete dashboard JSON into EC2 user-data exceeded the AWS user-data size limit.

Resolution:

- dashboards were exported as JSON files
- dashboard JSON is stored in the repository
- dashboards are imported manually into Grafana after recreating the monitoring instance

## Terraform dependency cycle

The application and monitoring instances initially depended on each other's private IP addresses.

Resolution:

- assigned a Terraform-managed private IP to the monitoring EC2
- kept the application private IP dynamically managed
- removed the circular Terraform dependency

---

# Design Decisions

## EC2 instead of EKS

EKS would provide a more production-oriented orchestration platform, but EC2 was chosen because:

- the assignment time limit was 3 days
- the application is a single small service
- EC2 keeps the infrastructure easier to understand and demonstrate
- the deployment requirements can still be fulfilled with Docker and SSM

## Prometheus/Grafana/Loki instead of CloudWatch

Prometheus, Grafana and Loki provide an open-source observability stack that demonstrates:

- metrics collection
- dashboarding
- application monitoring
- centralized logging

without coupling the monitoring implementation entirely to AWS.

## Secrets Manager

Secrets Manager was selected as the assignment's secret-management implementation.

It prevents database credentials from being committed to source control and allows EC2 workloads to retrieve credentials through IAM.

---

# Known Limitations

This solution is designed for the assignment timebox rather than production scale.

Known limitations include:

- single monitoring EC2
- single NAT Gateway
- manual Grafana dashboard import after monitoring EC2 recreation
- non-blocking vulnerability scans because the base application has known dependency findings
- no autoscaling
- no HTTPS certificate configuration
- local Loki storage rather than durable object storage
- simplified production topology using the same application infrastructure pattern

These are documented trade-offs rather than omitted requirements.

---

# Conclusion

The implementation demonstrates the requested DevOps workflow from infrastructure provisioning through CI/CD and observability:

```text
Terraform
   ↓
AWS Infrastructure
   ↓
Docker Application
   ↓
GitHub Actions
   ↓
ECR
   ↓
SSM Deployment
   ↓
Application + PostgreSQL
   ↓
Prometheus / Grafana
   ↓
Alloy / Loki
```

The primary objective was to build a reproducible, secure and observable deployment while keeping the implementation practical for the assignment's 3-day time limit.