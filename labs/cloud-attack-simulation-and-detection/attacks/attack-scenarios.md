# Attack Simulation Scenarios

This lab demonstrates **three adversary behaviors** mapped to MITRE ATT&CK:

1. **Impossible Travel (Credential Access + Defense Evasion)**
   * Technique: T1078 Valid Accounts
   * Simulates compromised credentials logging in from two locations.

2. **Brute Force (Initial Access)**
   * Technique: T1110 Brute Force
   * Floods Azure AD with failed login attempts.

3. **Malicious Container Deployment (Execution + Persistence)**
   * Technique: T1204 User Execution / T1499 Resource Hijacking
   * Deploys a cryptominer workload to simulate resource theft.

---
## Blue Team Detection
* Sentinel KQL queries monitor login anomalies, brute-force attempts, and malicious container creation.
* Automated Sentinel playbooks can:
  - Block attacker IPs.
  - Disable compromised accounts.
  - Quarantine malicious containers.
