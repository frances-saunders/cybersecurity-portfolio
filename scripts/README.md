# Scripts

This folder contains **reusable, production-minded tooling** that supports the portfolio’s labs and case studies. Everything here is designed to be **stand-alone, parameterized, auditable**, and safe to run in CI/CD. Secrets are never embedded; use **OIDC, Azure Key Vault, HashiCorp Vault, or environment variables** as documented in each script.

---

## Subdirectory purposes

* ```automation/```   
  Operational utilities for day-to-day security engineering: bulk tasks, secret rotation, tagging/guardrails, packaging evidence, and similar repeatable workflows.

* ```compliance/```     
  Evidence collection, normalization, and reporting for frameworks (NIST, CIS, ISO, SOC 2). Includes helpers for POA\&M generation, secure score collection, and config validation to support audit readiness.

* ```detection-response/```     
  Detection engineering and incident response helpers: rule linting/promotion, threat-intel processing, containment actions, enrichment, and synthetic smoke tests for SIEM/SOAR pipelines.

* ```dfir/```     
  Digital forensics and incident response triage. Host live-response collectors, timeline exports, and integrity manifests aimed at rapid, low-impact evidence gathering.

* ```hardening/```     
  Baseline and benchmark enforcement across OS, containers, Kubernetes, and IAM. Includes guardrails and checks that can gate deployments in CI.

* ```integration/```     
  Cross-platform glue code that connects services (e.g., cloud → SIEM, Splunk ↔ Sentinel, S3 → ADLS). Emphasizes secure identity (OIDC) and secret-less automation.

* ```ml-security/```     
  Applied analytics for security data (e.g., anomaly detection, drift monitoring). Designed to run offline on exported datasets or inline in batch jobs and push results back to SIEM.

* ```observability/```     
  Health checks and SLOs for the security data plane: connector status, ingestion lag, workbook export/versioning. Intended for continuous monitoring and CI/cron.

* ```pqc/```     
  Post-quantum cryptography demos and planning utilities (e.g., rotation scheduling, readiness assessment) to support future-proofing crypto posture.

---

## How to use these scripts

* **Dry-run first**
  Most scripts support `--dry-run` (bash/python) or `-WhatIf` (PowerShell). Use it before making changes.

* **Identity & secrets**

  * Prefer **OIDC/workload identity** for CI.
  * For cloud credentials, use **Azure Key Vault** or **HashiCorp Vault**; never commit secrets.
  * Environment variables are accepted for short-lived tokens (e.g., `AZ_TOKEN`, `WORKSPACE_ID`, `SHARED_KEY`, `SPLUNK_TOKEN`).

* **Logging & output**
  Scripts emit **structured output** (JSON/CSV) suitable for pipelines. Non-zero exit codes indicate policy violations or errors to **gate** builds.

* **Cross-platform**
  PowerShell scripts target Windows/Cloud; bash targets Linux/macOS; Python targets 3.9+ with clear dependency headers. Install requirements per script (`pip install …`).

---

## Conventions

* **Naming**: verbs for actions (e.g., `tag-enforcer`, `poam-generator`), nouns for collectors (`triage-collector-*`).
* **Idempotence**: scripts should be safe to re-run; creation/update operations check for existing state.
* **Security posture**: no plaintext secrets; redact PII in outputs where applicable; least-privilege by default.
* **Testing**: where relevant, include sample data and CI-friendly flags; linting/testing scripts return actionable exit codes.
* **Docs**: each script contains a header with synopsis, requirements, parameters, examples, and exit behavior.

---

## Quick start

```bash
# Linux/macOS
cd scripts
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt  # if present

# Example dry-run of a guardrail
python automation/tag-enforcer.py --subscription-id <SUB> --dry-run

# Example health check
python observability/connector-health-check.py --workspace-id <WS> --tables SecurityEvent OfficeActivity
```

```powershell
# Windows/PowerShell
cd scripts
# Example: WhatIf on an Azure OIDC setup
.\integration\github-oidc-azure-setup.ps1 -AppDisplayName 'gha-ci' -GithubOrg 'org' -GithubRepo 'repo' -WhatIf
```

---

## Contribution checklist

* Add **parameters**, **dry-run/WhatIf**, and **clear error messages**.
* Validate inputs; fail fast with non-zero exit codes.
* Emit **machine-readable artifacts** (JSON/CSV/SARIF) when possible.
* Document **prerequisites** and **least-privilege permissions** in the script header.
* Avoid side effects unless explicitly requested by flags.

---

This folder is intentionally **ever-growing**. New scripts should follow the same standards so they can be reused across labs, case studies, and real-world environments.
