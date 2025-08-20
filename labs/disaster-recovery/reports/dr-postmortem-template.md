# Disaster Recovery Test – Post-Mortem & Lessons Learned

## Event Summary

* **Test Date:** YYYY-MM-DD
* **Scope:** \[e.g., Tier 1 ERP + Payment Gateway systems]
* **Scenario Simulated:** \[e.g., Full regional outage in East US]
* **Objective:** Validate Recovery Time Objective (RTO) and Recovery Point Objective (RPO) for critical workloads.

---

## Incident Timeline

| Timestamp (UTC) | Action                                          | Owner        | Notes                             |
| --------------- | ----------------------------------------------- | ------------ | --------------------------------- |
| 10:00           | Test initiated – production system powered down | DR Lead      | Confirmed clean failover scenario |
| 10:05           | DNS failover initiated                          | Network Team | TTL pre-staged at 30s             |
| 10:20           | DR site ERP brought online                      | App Team     | Initial login tests successful    |
| 10:30           | Database sync verified                          | DBA          | RPO validated at 12 min           |
| 10:55           | ERP fully operational for users                 | App Team     | RTO achieved at 55 min            |

---

## Results vs. Targets

| System          | Target RTO | Achieved RTO | Target RPO | Achieved RPO | Status      |
| --------------- | ---------- | ------------ | ---------- | ------------ | ----------- |
| ERP             | 1 hr       | 55 min       | 15 min     | 12 min       | Compliant   | 
| Payment Gateway | 1 hr       | 55 min       | 15 min     | 14 min       | Compliant   | 
| Customer Portal | 1 hr       | 55 min       | 15 min     | 12 min       | Compliant   |

---

## What Went Well

* Pre-staging DNS TTL enabled faster failover than previous tests.
* Automation scripts reduced manual intervention for database restores.
* Clear runbook ownership minimized confusion during recovery.

---

## Issues Encountered 

* VPN concentrator took longer than expected to failover (\~8 minutes).
* Inconsistent timestamp logging between teams delayed timeline validation.
* End-user testing was ad hoc instead of structured.

---

## Lessons Learned

* Standardize timestamp logging across all teams for better auditability.
* Create automated health checks to validate application availability post-failover.
* Expand tabletop exercises to cover third-party service dependencies.

---

## Action Items 

| Item                             | Owner        | Due Date | Status      |
| -------------------------------- | ------------ | -------- | ----------- |
| Automate VPN failover validation | Network Team | +30 days | In Progress |
| Standardize logging template     | DR Lead      | +15 days | Not Started |
| Formalize end-user test cases    | App Team     | +45 days | Planned     |

---

## Next Steps

* Schedule follow-up DR validation in 6 months.
* Include lessons learned into updated **DR Playbook v2.0**.
* Conduct tabletop exercise focusing on multi-region failover.
