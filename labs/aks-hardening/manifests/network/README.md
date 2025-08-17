## Troubleshooting

If traffic is not behaving as expected, start by confirming labels and selectors. NetworkPolicies match pods by label, so a missing or misspelled label is the most common cause. Verify that the namespace is set correctly in every manifest and that application pods carry the labels referenced by the policies.

```bash
kubectl -n <your-namespace> get pods --show-labels
kubectl -n <your-namespace> get networkpolicy
kubectl -n <your-namespace> describe networkpolicy default-deny-all
kubectl -n <your-namespace> describe networkpolicy allow-frontend-to-backend
````

Validate ingress and egress with simple runtime checks. Use a temporary debug pod in the same namespace to attempt connections that should be allowed or denied. Replace hostnames, ports, and selectors with values that match your setup.

```bash
kubectl -n <your-namespace> run netcheck --image=busybox:1.36 --restart=Never -it -- sh
# inside the pod:
wget -qO- http://backend:8080 || echo "blocked as expected"
nc -vz backend 8080 || echo "blocked as expected"
nslookup kubernetes.default.svc.cluster.local || echo "dns blocked"
```

Confirm DNS allow rules are effective. If `nslookup` fails after applying the default-deny policy, ensure the DNS allow policy targets CoreDNS correctly. Some clusters label CoreDNS as `k8s-app=kube-dns` in `kube-system`, others may use different labels. Adjust the `namespaceSelector` and `podSelector` in `allow-dns-egress.yaml` to match your cluster.

```bash
kubectl -n kube-system get pods -l k8s-app=kube-dns -o wide
kubectl -n kube-system get pods --show-labels | grep -i dns
```

Check CNI behavior and limitations. Kubernetes NetworkPolicy is implemented by the cluster CNI; capabilities vary. Azure CNI and Calico support the patterns shown here, but FQDN-based egress rules require an egress controller or advanced CNI features. If you used an IPBlock placeholder for ACR, replace it with your private endpoint subnet or the actual egress CIDR, then re-apply.

```bash
kubectl -n <your-namespace> apply -f network/allow-egress-to-acr.yaml
```

Apply order can mask results. Always apply the baseline deny first, then layer the allows. Re-apply if you edit selectors or ports. After changes, delete and recreate the debug pod to ensure it picks up current policies.

```bash
kubectl -n <your-namespace> apply -f network/default-deny-all.yaml
kubectl -n <your-namespace> apply -f network/allow-dns-egress.yaml
kubectl -n <your-namespace> apply -f network/allow-frontend-backend.yaml
kubectl -n <your-namespace> delete pod netcheck --ignore-not-found
kubectl -n <your-namespace> run netcheck --image=busybox:1.36 --restart=Never -it -- sh
```

When nothing matches, use targeted describes to spot selector mismatches. Start with the backend pods and ensure they carry `tier=backend` (or whatever label your policy expects). Do the same for frontend. Update either the Deployment labels or the policy selectors so they align exactly.

```bash
kubectl -n <your-namespace> get deploy -o yaml | grep -A3 "labels:"
kubectl -n <your-namespace> get pods -l tier=backend
kubectl -n <your-namespace> get pods -l tier=frontend
```
