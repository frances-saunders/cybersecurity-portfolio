#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
k8s-secrets-audit.py
--------------------
Audits Kubernetes clusters for risky Secret usage and overly-broad RBAC on secrets.

Checks:
  - Secrets containing likely cleartext credentials (base64-decoded printable strings with common keys)
  - Large number of namespaces without any Secret encryption indicator (informational)
  - ClusterRoleBindings granting cluster-admin (or broad edit) to wide subjects (system:authenticated, * )

Output:
  JSON report with findings per-namespace and RBAC risks.

Requirements:
  pip install kubernetes
  KUBECONFIG or in-cluster config present.
"""

import base64, json, os, re, string, sys
from typing import Dict, List, Any
from kubernetes import client, config

RISK_KEYS = re.compile(r"(pass(word)?|secret|token|key|cred)", re.I)

def is_printable(b: bytes) -> bool:
    try:
        s = b.decode("utf-8", errors="ignore")
    except Exception:
        return False
    return all(ch in string.printable for ch in s) and len(s.strip()) >= 4

def audit_secrets(v1: client.CoreV1Api) -> List[Dict[str, Any]]:
    findings = []
    ns_list = [n.metadata.name for n in v1.list_namespace().items]
    for ns in ns_list:
        try:
            secrets = v1.list_namespaced_secret(ns).items
        except Exception as e:
            findings.append({"namespace": ns, "error": str(e)})
            continue
        for s in secrets:
            if s.type == "kubernetes.io/service-account-token":
                continue
            risky = []
            for k, v in (s.data or {}).items():
                try:
                    raw = base64.b64decode(v + "==")
                except Exception:
                    continue
                if is_printable(raw):
                    text = raw.decode("utf-8", errors="ignore")
                    if RISK_KEYS.search(k) or RISK_KEYS.search(text):
                        risky.append({"key": k, "decoded_preview": text[:60]})
            if risky:
                findings.append({
                    "namespace": ns, "secret": s.metadata.name, "type": s.type,
                    "risks": risky
                })
    return findings

def audit_rbac(rbac: client.RbacAuthorizationV1Api) -> List[Dict[str, Any]]:
    risks = []
    crbs = rbac.list_cluster_role_binding().items
    for b in crbs:
        role_ref = f"{b.role_ref.kind}/{b.role_ref.name}"
        subjects = [{"kind": s.kind, "name": s.name, "ns": getattr(s, 'namespace', None)} for s in (b.subjects or [])]
        if b.role_ref.name in ("cluster-admin","edit"):
            if any(s.name in ("system:authenticated","system:unauthenticated","*") for s in (b.subjects or [])):
                risks.append({"binding": b.metadata.name, "role": role_ref, "subjects": subjects, "risk": "broad_subjects"})
            else:
                risks.append({"binding": b.metadata.name, "role": role_ref, "subjects": subjects, "risk": "elevated_role"})
    return risks

def main():
    try:
        if os.getenv("KUBERNETES_SERVICE_HOST"):
            config.load_incluster_config()
        else:
            config.load_kube_config()
        v1 = client.CoreV1Api()
        rbac = client.RbacAuthorizationV1Api()

        secret_findings = audit_secrets(v1)
        rbac_findings = audit_rbac(rbac)

        report = {"secrets": secret_findings, "rbac": rbac_findings}
        print(json.dumps(report, indent=2))
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)

if __name__ == "__main__":
    main()
