# Disaster Recovery Playbook (Sanitized Excerpt)

## Tier 1 Application Recovery Workflow

| Step | Action                             | Tool / Owner                     | Target Time | Notes                                              |
| ---- | ---------------------------------- | -------------------------------- | ----------- | -------------------------------------------------- |
| 1    | Trigger DR Incident (Severity 1)   | Incident Commander (Ops Lead)    | Immediate   | Declare outage in ServiceNow, notify stakeholders  |
| 2    | Validate outage scope              | DR Team                          | < 10 min    | Confirm application/service unavailability         |
| 3    | Failover Compute + Storage         | Azure Site Recovery / VMware SRM | < 20 min    | Trigger automated failover of VMs & disks          |
| 4    | Switch Database to Replica         | SQL Always On / DBA Team         | < 15 min    | Validate data replication status before cutover    |
| 5    | Update DNS + Load Balancers        | Terraform / NetOps               | < 5 min     | Cut traffic to recovered environment               |
| 6    | Validate Application Functionality | App Owners                       | < 5 min     | Perform smoke tests & confirm service availability |
| 7    | Business Notification              | Comms Lead                       | < 5 min     | Send “Service Restored” notification               |

**Total Target RTO: < 55 minutes**

---

## Escalation Matrix

| Role                   | Responsibility                    | Escalation Contact | Backup Contact       |
| ---------------------- | --------------------------------- | ------------------ | -------------------- |
| Incident Commander     | Declares DR, manages workflow     | Ops Manager        | CTO                  |
| Database Recovery Lead | Ensures DB replica cutover        | Lead DBA           | Sr. DBA              |
| Network Recovery Lead  | DNS & Load Balancer updates       | Network Lead       | Sr. Network Engineer |
| Comms Lead             | Internal + External notifications | IT Comms Manager   | CIO                  |

---

## Communication Templates

**Initial DR Declaration (Internal):**

> *Subject:* 🚨 DR Declared – \[System Name] Unavailable
> *Message:* A disaster recovery event has been declared for **\[System Name]** at **\[Time UTC]**. DR procedures are in progress. Estimated RTO: **< 1 hour**. Next update in 15 minutes.

**Service Restored (Internal & External):**

> *Subject:* ✅ DR Recovery Complete – \[System Name] Restored
> *Message:* **\[System Name]** was successfully restored via DR procedures at **\[Time UTC]**. RTO achieved: **55 minutes**. Root cause analysis will follow in post-mortem report.
