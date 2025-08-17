# AKS RBAC & NetworkPolicy Manifests

## Purpose
These manifests demonstrate namespace-scoped least-privilege access and traffic control for AKS. They complement the AKS Security Baseline Initiative by enforcing workload-level controls inside the cluster, while the initiative governs policy compliance at the subscription scope.

## Prerequisites
You should have `kubectl` configured against an AKS cluster and a target namespace created. Replace placeholder values such as `<your-namespace>`, `<aad-group-name-or-id>`, and `<ops-readonly-group>` with demo-safe values.

## Apply RBAC
Update the namespace and group placeholders in the files below, then apply them. Order does not matter, but creating Roles before RoleBindings is conventional.

```bash
kubectl apply -f rbac/pod-reader-role.yaml
kubectl apply -f rbac/dev-role.yaml
kubectl apply -f rbac/dev-rolebinding.yaml
````

Validate by describing the bindings and attempting a read-only pod logs action as a member of the reader group.

```bash
kubectl -n <your-namespace> describe rolebinding bind-pod-reader
kubectl -n <your-namespace> logs deploy/<some-deployment> --tail=10
```

## Apply Network Policies (optional)

If you add NetworkPolicy manifests under `manifests/network/`, apply them after verifying your namespace and labels. Begin with a default-deny policy and then layer explicit allow rules.

```bash
kubectl apply -f network/default-deny-all.yaml
kubectl apply -f network/allow-frontend-backend.yaml
```

Confirm enforcement by checking that pods without matching allow rules cannot reach each other and by reviewing events.

```bash
kubectl -n <your-namespace> get networkpolicy
kubectl -n <your-namespace> describe networkpolicy default-deny-all
```

## How This Complements the Initiative

The AKS Security Baseline Initiative enforces guardrails such as privileged container denial, approved registry restrictions, and the requirement for NetworkPolicy. These manifests operationalize those guardrails by defining the concrete roles, bindings, and network rules developers work within. Together, they provide governance at assignment scope and practical enforcement inside the cluster.

## Cleanup

Remove the resources with delete commands if you need to reset the environment.

```bash
kubectl delete -f rbac/dev-rolebinding.yaml
kubectl delete -f rbac/dev-role.yaml
kubectl delete -f rbac/pod-reader-role.yaml
kubectl delete -f network/allow-frontend-backend.yaml
kubectl delete -f network/default-deny-all.yaml
```
