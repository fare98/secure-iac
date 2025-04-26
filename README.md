# Secure‑IDP‑Pipeline \- Infrastructure‑as‑Code Monorepo

> **Purpose**  
> Single‑click (or single‑script) provisioning, hardening and compliance scanning of Proxmox VMs using Terraform \+ Jenkins \+ Ansible \+ OPA.

---

## 1. High‑level flow

```text
Client   ── launch_pipeline.sh ─▶  Jenkins ◀── seed job
                                │
                                ├─ Lint / Static‑Security (tfsec, checkov)
                                ├─ Policy‑Gate (OPA)
                                ├─ Terraform Plan ▸ Apply  ─▶  Proxmox VMs
                                └─ Ansible Hardening         ─▶  Hardened hosts
```

*All tasks, rules and secrets live in this repository so a fresh VM can rebuild the entire stack from scratch.*

---

## 2. Repository layout (recap)

```text
.
├── ansible/           # post‑deployment configuration & hardening
│   ├── inventories/   # per‑env host lists (lab, prod …)
│   ├── roles/         # → harden/, monitoring_agent/, …
│   └── site.yml       # entry playbook called by CI or humans
├── cicd/              # Jenkins bootstrap & pipeline code
│   ├── Jenkinsfile    # multistage CI/CD
│   └── seed/          # job‑DSL that creates the multibranch job
├── scripts/           # client‑side helpers
│   ├── launch_pipeline.sh
│   └── validate_input.sh
├── security/          # scanner config & generated reports
├── terraform/         # IaC
│   ├── modules/       # reusable building‑blocks (vm/, …)
│   ├── envs/          # env‑specific wrappers (lab/, prod/ …)
│   └── opa‑policies/  # rego policy files
├── .gitignore
├── Makefile           # local dev shortcuts (lint, plan, apply …)
└── README.md          # this file
```

---

## 3. Quick start (lab environment)

```bash
# clone & enter
$ git clone <repo> secure-idp && cd secure-idp

# create/adjust secrets (never commit!)
$ cp ansible/vault.pass.example ansible/vault.pass
$ export PROXMOX_TOKEN_ID=… PROXMOX_TOKEN_SECRET=…

# optional: run locally without Jenkins
$ make plan   ENV=lab   # show what would be created
$ make apply  ENV=lab   # create VMs then harden them
```

### Via Jenkins (recommended)

```bash
$ scripts/launch_pipeline.sh        # interactive wizard
```
Jenkins takes over and the pipeline logs appear in the web UI.

---

## 4. Jenkins‑pipeline stages

| Stage                | Key commands                                                         |
|----------------------|-----------------------------------------------------------------------|
| **Lint**             | `tflint`, `terraform fmt -check`, `ansible-lint`                      |
| **Static‑Security**  | `tfsec`, `checkov`                                                    |
| **Policy‑Gate (OPA)**| `opa eval --fail-defined …`                                           |
| **Plan**             | `terraform plan -out=plan.tfplan`                                     |
| **Apply**            | `terraform apply plan.tfplan`                                         |
| **Ansible**          | `ansible-playbook site.yml` against newly‑created VMs                 |

Build stops on any security or policy violation **before** resources are created.

---

## 5. Important code bits

| File / Dir                               | What it does |
|------------------------------------------|--------------|
| `scripts/launch_pipeline.sh`             | Gets user input, writes `terraform.tfvars.json`, triggers Jenkins REST API |
| `cicd/Jenkinsfile`                       | Declarative pipeline containing all stages above |
| `terraform/modules/vm`                   | Re‑usable module to clone a template, size CPU/RAM, attach networks |
| `terraform/envs/lab`                     | Thin wrapper that sets provider creds & calls `module "vm"` |
| `terraform/opa-policies/terraform.rego`  | Sample deny‑rule (VM > 16 vCPU)|
| `ansible/roles/harden`                   | Zero‑Trust hardening (UFW, SSH, etc.) |
| `Makefile`                               | Single entry point for lint/plan/apply/destroy |

---

## 6. Secrets & placeholders


---

## 7. Extending the stack


---

## 8. Troubleshooting



