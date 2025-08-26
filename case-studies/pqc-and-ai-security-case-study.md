# Case Study: Post-Quantum Cryptography & AI-Driven Anomaly Detection

## Problem / Challenge

As organizations prepare for the quantum era, traditional cryptographic schemes like RSA and ECC face eventual obsolescence. Attackers equipped with quantum computers could break these algorithms, exposing sensitive communications. Simultaneously, adversaries are leveraging increasingly sophisticated attack patterns that overwhelm human analysts and static detection rules.

The challenge addressed in this project was twofold:

1. **Future-proof cryptography:** Demonstrate a secure key exchange using **post-quantum cryptography (PQC)** to safeguard against quantum-capable adversaries.
2. **Scalable detection:** Build an **AI-driven anomaly detection system** capable of learning normal system behavior and identifying deviations indicative of insider threats or zero-day attacks.

---

## Tools & Technologies
* Python (cryptography, scikit-learn, PyTorch)
* NIST PQC Candidate Algorithms (Kyber KEM)
* Jupyter Notebook
* Sanitized log data (HTTP access logs, syslog)

---

## Actions Taken

### PQC Demo
* Implemented a **lattice-based key encapsulation mechanism (KEM)** using Kyber.
* Demonstrated secure session key exchange without relying on RSA/ECC.
* Used **secrets sourced from a vault service** (no plaintext credentials).

### AI Anomaly Detector
* Collected sanitized log data simulating normal vs. anomalous traffic.
* Built an **unsupervised anomaly detection pipeline** using Isolation Forest and Autoencoder models.
* Validated detection accuracy against injected anomalies.
* Packaged detection logic into a Python script for integration into SIEM/SOAR pipelines.

---

## Results / Impact
* **Cryptographic Readiness:** Validated feasibility of PQC adoption in enterprise workflows, ensuring resilience against quantum threats.
* **Proactive Threat Detection:** AI-driven detection flagged insider-like anomalies invisible to static rules.
* **Research Integration:** Extended my PhD research on **device-independent authentication with partial entanglement** into a practical demonstration of how cryptography and AI complement each other in cybersecurity.
* **Executive Value:** Presented a **forward-looking blueprint** for boards and CISOs to prepare for PQC migration while scaling detection capabilities with AI.

---

## Artifacts
* `pqc_key_exchange.py` – lattice-based key exchange demo.
* `anomaly_detector.py` – unsupervised AI anomaly detection.
* `training_notebook.ipynb` – end-to-end ML workflow.
* Sanitized log datasets.

---

## Key Takeaways
This project demonstrates:
* **Thought leadership** in emerging cybersecurity technologies.
* Ability to operationalize **PQC** and integrate it with enterprise security workflows.
* Expertise in applying **AI for scalable detection** in complex environments.
* Unique credibility in bridging **academic quantum cryptography research** with **enterprise-ready cybersecurity engineering**.
