# 💸 Expense App — Terraform Multi-Environment Infrastructure (tfvars Strategy)

> Terraform IaC to provision and manage **dev**, **uat**, and **prod** AWS environments for the **Expense** application using per-environment `.tfvars` files and isolated S3 remote state backends.

---

## 📌 Repository Description

> _"Terraform configuration that provisions AWS EC2 instances (MySQL, Backend, Frontend), Security Groups, and Route 53 DNS records for the Expense application. Each environment (dev/uat/prod) is controlled via its own `.tfvars` and backend configuration, sharing a single root module codebase."_

---

## 🏗️ Repository Structure

```
expense-terraform-multi-env-tfvars/
│
├── provider.tf          # AWS provider (~> 6.0) + S3 remote backend declaration
├── variables.tf         # Input variable declarations (components, environment, tags, etc.)
├── locals.tf            # Computed locals — instance sizing, naming conventions, DNS names
├── data.tf              # Data sources — AMI lookup + Route 53 zone query
├── infra.tf             # Core resources — EC2 instances, Security Group, R53 records
│
├── dev/
│   ├── backend.tf       # S3 backend config for dev state
│   └── dev.tfvars       # Dev environment variable overrides
│
├── uat/
│   ├── backend.tf       # S3 backend config for uat state
│   └── uat.tfvars       # UAT environment variable overrides
│
└── prod/
    ├── backend.tf       # S3 backend config for prod state
    └── prod.tfvars      # Prod environment variable overrides
```

---

## ☁️ Infrastructure Provisioned

This configuration provisions the following AWS resources per environment:

| Resource | Details |
|---|---|
| **EC2 Instances** | 3 instances — `mysql`, `backend`, `frontend` (count-driven via `var.components`) |
| **AMI** | Custom `Redhat-9-DevOps-Practice` image — queried dynamically via `data.aws_ami` |
| **Instance Type** | `t3.large` → prod &nbsp;/&nbsp; `t3.micro` → dev & uat (conditional in `locals.tf`) |
| **Security Group** | Dynamic ingress/egress on ports `22` (SSH), `80` (HTTP), `3306` (MySQL) |
| **Route 53 (Private)** | A-records for all 3 components pointing to their private IPs |
| **Route 53 (Public)** | A-record for the `frontend` component pointing to its public IP |
| **Domain** | `rscloudservices.icu` |

---

## 🌍 Environments

| Environment | tfvars File | Backend State Key | Instance Type |
|---|---|---|---|
| `dev` | `dev/dev.tfvars` | `expense-teffaform-state-dev-env` | `t3.micro` |
| `uat` | `uat/uat.tfvars` | `expense-teffaform-state-uat-env` | `t3.micro` |
| `prod` | `prod/prod.tfvars` | `expense-teffaform-state-prod-env` | `t3.large` |

All environments share the same **S3 bucket** (`expense-state-lock-tfvars`) with isolated state keys and native S3 file locking (`use_lockfile = true` — no DynamoDB required).

---

## 🏷️ Naming Convention

All resources follow a consistent naming pattern driven by `locals.tf`:

```
common_name      = <environment>-expense-use1
                   e.g. dev-expense-use1

EC2 Name tag     = <component>-<common_name>
                   e.g. mysql-dev-expense-use1

Private DNS      = <component>-<common_name>.<domain>
                   e.g. mysql-dev-expense-use1.rscloudservices.icu

Public DNS       = expense.<environment>.<domain>
                   e.g. expense.dev.rscloudservices.icu
```

---

## ⚙️ Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| Terraform | `>= 1.14` | Infrastructure provisioning (uses native S3 locking) |
| AWS CLI | Latest | Authentication & credential management |
| AWS Account | — | Valid account with permissions for EC2, SG, R53, S3 |

> Ensure AWS credentials are configured via `aws configure`, environment variables, or an IAM instance profile before running any commands.

---

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/rahul-paladugu/expense-terraform-multi-env-tfvars.git
cd expense-terraform-multi-env-tfvars
```

### 2. Initialize Terraform with Environment-Specific Backend

Each environment has its own `backend.tf` inside its folder. Pass it during `init` using `-backend-config`:

```bash
# Development
terraform init -backend-config="dev/backend.tf"

# UAT
terraform init -backend-config="uat/backend.tf"

# Production
terraform init -backend-config="prod/backend.tf"
```

> 💡 Run `terraform init -reconfigure -backend-config="<env>/backend.tf"` when **switching between environments** to reconfigure the backend.

---

## 🔄 Plan & Apply Per Environment

### Development

```bash
terraform init -backend-config="dev/backend.tf"
terraform plan  -var-file="dev/dev.tfvars"
terraform apply -var-file="dev/dev.tfvars"
```

### UAT

```bash
terraform init -reconfigure -backend-config="uat/backend.tf"
terraform plan  -var-file="uat/uat.tfvars"
terraform apply -var-file="uat/uat.tfvars"
```

### Production

```bash
terraform init -reconfigure -backend-config="prod/backend.tf"
terraform plan  -var-file="prod/prod.tfvars" -out=prod.tfplan
terraform apply prod.tfplan
```

> 🛑 **Always save a plan file (`-out`) before applying to production.** This ensures exactly what was reviewed gets applied — no surprises.

---

## 🗂️ Remote State Management

State is stored in S3 with **native file-based locking** (Terraform `>= 1.14` feature):

```hcl
# provider.tf
backend "s3" {}   # Partial config — completed at init time via -backend-config

# dev/backend.tf
bucket       = "expense-state-lock-tfvars"
key          = "expense-teffaform-state-dev-env"
region       = "us-east-1"
encrypt      = true
use_lockfile = true   # Native S3 locking — no DynamoDB table needed
```

Each environment writes to an **isolated state key**, preventing any cross-environment state conflicts.

---

## 📋 Variable Reference

| Variable | Type | Default | Description |
|---|---|---|---|
| `environment` | `string` | _(required)_ | Target environment — set via `.tfvars` (`dev` / `uat` / `prod`) |
| `project` | `string` | `"expense"` | Project name — used in resource naming and tags |
| `region` | `string` | `"use1"` | Short region code used in resource naming |
| `components` | `list` | `["mysql", "backend", "frontend"]` | EC2 instances to provision |
| `sg_ports` | `list` | `["22", "80", "3306"]` | Ports opened on the Security Group |
| `r53_record_name` | `string` | `"rscloudservices.icu"` | Base Route 53 domain name |
| `common_tags` | `map` | `{Terraform="true", Project="expense"}` | Tags applied to all resources |

---

## 📤 Outputs

> Add an `outputs.tf` to expose useful values post-apply. Recommended outputs:

| Suggested Output | Description |
|---|---|
| `instance_ids` | List of EC2 instance IDs for all components |
| `instance_private_ips` | Private IPs of mysql / backend / frontend |
| `frontend_public_ip` | Public IP of the frontend instance |
| `public_dns` | Public Route 53 URL — `expense.<env>.rscloudservices.icu` |
| `security_group_id` | ID of the provisioned Security Group |

---

## 🔐 Secrets & Security Notes

- **Never commit AWS credentials** to this repository
- Use `aws configure` or `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` environment variables
- The `.terraform/` directory and `terraform.tfstate` files are excluded from commits via `.gitignore`
- S3 state encryption is **enabled** (`encrypt = true`) in all environments

Recommended `.gitignore`:

```gitignore
.terraform/
*.tfstate
*.tfstate.backup
*.tfplan
.env
*.tfvars.local
```

---

## 🧪 Validation & Linting

Run these before every commit or PR:

```bash
# Auto-format all .tf files
terraform fmt -recursive

# Validate configuration syntax
terraform validate

# Security scan (install tfsec or checkov)
tfsec .
# or
checkov -d .
```

---

## 🧹 Destroying Infrastructure

> ⚠️ **Destructive — double-check your active backend config before running destroy.**

```bash
# Destroy dev
terraform init -reconfigure -backend-config="dev/backend.tf"
terraform destroy -var-file="dev/dev.tfvars"

# Destroy uat
terraform init -reconfigure -backend-config="uat/backend.tf"
terraform destroy -var-file="uat/uat.tfvars"

# Destroy prod (extra caution!)
terraform init -reconfigure -backend-config="prod/backend.tf"
terraform destroy -var-file="prod/prod.tfvars"
```

---

## 🔁 Switching Between Environments (Quick Reference)

```bash
# Always re-init with -reconfigure when switching envs
terraform init -reconfigure -backend-config="<env>/backend.tf"
terraform plan  -var-file="<env>/<env>.tfvars"
terraform apply -var-file="<env>/<env>.tfvars"
```

---

## 👤 Author

**Rahul Paladugu**
- GitHub: [@rahul-paladugu](https://github.com/rahul-paladugu)

---

> _Built with ❤️ using Terraform `~> 1.14` and AWS Provider `~> 6.0`. Single codebase. Three environments. Zero configuration drift._
