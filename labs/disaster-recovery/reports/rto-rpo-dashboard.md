# RTO/RPO Compliance Dashboard (Sanitized Example)

This dashboard illustrates validated **Recovery Time Objective (RTO)** and **Recovery Point Objective (RPO)** metrics across Tier 1–3 applications following recent DR testing.

---

## Summary by Application Tier

| Tier              | Applications                          | Target RTO | Achieved RTO | Target RPO | Achieved RPO | Status      |
| ----------------- | ------------------------------------- | ---------- | ------------ | ---------- | ------------ | ----------- |
| Tier 1 (Critical) | ERP, Payment Gateway, Customer Portal | 1 hour     | 55 min       | 15 min     | 12 min       | ✅ Compliant |
| Tier 2 (High)     | HRIS, CRM, Analytics                  | 4 hours    | 2 hr 45 min  | 1 hour     | 45 min       | ✅ Compliant |
| Tier 3 (Standard) | Intranet, File Shares                 | 24 hours   | 10 hr 20 min | 12 hours   | 6 hr 30 min  | ✅ Compliant |

---

## Trend of RTO Validation (Last 4 Quarters)

```
Tier 1: 70 min → 65 min → 60 min → 55 min
Tier 2: 3 hr 45 min → 3 hr 15 min → 3 hr 00 min → 2 hr 45 min
Tier 3: 14 hr 30 min → 12 hr 20 min → 11 hr 10 min → 10 hr 20 min
```

**Observation:** RTO consistently decreased quarter-over-quarter as automation reduced manual recovery steps.

---

## Compliance Heatmap

| System          | Q1 | Q2 | Q3 | Q4 |
| --------------- | -- | -- | -- | -- |
| ERP             | ❌  | ✅  | ✅  | ✅  |
| Payment Gateway | ❌  | ✅  | ✅  | ✅  |
| Customer Portal | ❌  | ❌  | ✅  | ✅  |
| HRIS            | ✅  | ✅  | ✅  | ✅  |
| CRM             | ❌  | ✅  | ✅  | ✅  |
| Analytics       | ❌  | ❌  | ✅  | ✅  |
| Intranet        | ✅  | ✅  | ✅  | ✅  |
| File Shares     | ✅  | ✅  | ✅  | ✅  |

✅ = Met RTO/RPO targets, ❌ = Missed targets

---

## Example Raw Data (CSV Export)

```csv
System,Tier,Target_RTO,Achieved_RTO,Target_RPO,Achieved_RPO,Quarter,Status
ERP,1,60,55,15,12,Q4,Compliant
Payment Gateway,1,60,55,15,14,Q4,Compliant
Customer Portal,1,60,55,15,12,Q4,Compliant
HRIS,2,240,165,60,45,Q4,Compliant
CRM,2,240,170,60,50,Q4,Compliant
Analytics,2,240,165,60,42,Q4,Compliant
Intranet,3,1440,620,720,390,Q4,Compliant
File Shares,3,1440,620,720,390,Q4,Compliant
```
