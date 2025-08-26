# PQC and AI Security 

## Overview
This lab demonstrates the integration of **emerging technologies** into enterprise security:

1. **Post-Quantum Cryptography (PQC):** Secure key exchange using lattice-based algorithms.  
2. **AI-Driven Anomaly Detection:** Machine learning models for identifying anomalous activity in logs.  

The goal is to highlight how **quantum-resistant cryptography** and **AI-powered analytics** can be operationalized together to address next-generation threats.

---

## Lab Structure
```plaintext
labs/pqc-and-ai-security/
│
├── pqc-demo/
│   ├── pqc_key_exchange.py
│   └── README.md
│
├── ai-anomaly-detector/
│   ├── anomaly_detector.py
│   └── training_notebook.ipynb
│
├── data/
│   ├── normal_traffic.log
│   └── anomalous_traffic.log
│
├── notebooks/
│   └── visualization.ipyn
│
├── github-workflows/
│   └── pqc-ai-lab.yml
│
├── scripts/
│   ├── ingest_logs.py
│   └── scheduler.yaml
│
├── vault/
│   ├── keyvault_setup.sh
│   └── vault_setup.ps1
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
│
└── attack-coverage-matrix.csv

````

---

## Tools & Technologies

* **Post-Quantum Cryptography (Kyber KEM)**
* **Python** (cryptography, scikit-learn, PyTorch)
* **Jupyter Notebook**
* **Vault Integration** for secrets (ensuring no plaintext keys are used)

---

## Setup & Deployment

1. Clone the lab directory.
2. Navigate to `pqc-demo/` and run:

   ```bash
   python3 pqc_key_exchange.py
   ```

   This simulates a PQC-based key exchange using vault-protected secrets.
3. Navigate to `ai-anomaly-detector/` and run:

   ```bash
   python3 anomaly_detector.py data/normal_traffic.log data/anomalous_traffic.log
   ```

   This executes the anomaly detection workflow on sanitized logs.

---

## Artifacts

* **PQC Key Exchange Demo** – lattice-based secure communication.
* **AI Anomaly Detector** – unsupervised ML-based detection logic.
* **Training Notebook** – end-to-end ML workflow for anomaly detection.
* **Sanitized Logs** – datasets for training and validation.

---

## Learning Outcomes

By completing this lab, I demonstrated:

* Practical application of **PQC algorithms** to secure communications.
* Building and operationalizing **AI-driven anomaly detection pipelines**.
* Secure handling of credentials through **vault integration**.
* Bridging **academic quantum cryptography research** with **enterprise-ready cybersecurity engineering**.

