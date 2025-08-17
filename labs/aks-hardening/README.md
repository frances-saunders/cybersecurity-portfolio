# AKS Security Hardening Lab

## Overview
This lab demonstrates representative examples of security controls applied to Azure Kubernetes Service (AKS).  
It focuses on **network restrictions, RBAC enforcement, and container image compliance**, reflecting the broader hardening work completed across production clusters.

The intent is to show recruiters and employers how I approach **Kubernetes security at scale**, while keeping actual work-specific scripts sanitized and generalized.

---

## Lab Objectives
- Apply **network security policies** to restrict pod-to-pod and pod-to-external communications.  
- Enforce **RBAC principles** by restricting cluster roles and binding them to least-privilege accounts.  
- Require **trusted container images** via Azure Policy and deny privileged container usage.  
- Demonstrate **logging, monitoring, and compliance validation** integrated into AKS.  

---

## Lab Structure
```
aks-hardening/
│
├── policies/                       # Custom Azure Policies for AKS
│   ├── block-privileged-containers.jsonc
│   ├── restrict-approved-registries.jsonc
│   └── enforce-network-policy.jsonc
│
├── manifests/                      # Kubernetes YAML Manifests
│   ├── rbac/                       
│   │   ├── dev-role.yaml
│   │   ├── dev-rolebinding.yaml
│   │   └── pod-reader-role.yaml
│   │
│   └── network/                    
│       ├── default-deny-all.yaml
│       └── allow-frontend-backend.yaml
│
├── terraform/                      # Infrastructure as Code Baseline
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
└── scripts/                        # Automation Scripts
    ├── compliance-scan.sh
    └── remediation.ps1
```
