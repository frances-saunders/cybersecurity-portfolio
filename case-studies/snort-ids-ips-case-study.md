# Case Study: Snort IDS/IPS Engineering and SIEM Integration

## Problem / Challenge
Organizations face increasing network threats ranging from brute force attacks and SQL injections to malware beaconing.  
While Snort provides a robust detection engine, its value depends on well-crafted rules, accurate tuning, and integration with enterprise visibility platforms like SIEMs.  
The challenge was to build a **repeatable detection pipeline** that could both identify and block malicious activity while minimizing false positives.

---

## Tools & Technologies
* Snort IDS/IPS
* Wireshark
* Splunk & Microsoft Sentinel
* Nmap, Metasploit
* Threat Intelligence feeds (IP/domain blocklists)

---

## Actions Taken

### 1. Snort Deployment
* Configured Snort in both **IDS mode (alert only)** and **IPS mode (inline blocking)**.  
* Deployed on a test subnet to monitor and actively block malicious traffic.  

### 2. Rule Engineering
* Authored custom rules for:  
  - SSH brute force detection  
  - SQL injection payloads  
  - Suspicious DNS queries to uncommon TLDs  
  - Malware C2 traffic  
* Tuned rules using **thresholds**, **flow directionality**, and **PCRE regex** for precision.

### 3. Attack Simulation
* Simulated real-world attacks:  
  - Nmap port scanning  
  - Metasploit malware beaconing  
  - SQL injection attempts against test web apps  
* Captured traffic in Wireshark and validated rule accuracy.  

### 4. SIEM Integration
* Configured Snort alerts to forward securely to **Splunk** (via log forwarder script) and **Microsoft Sentinel**.  
* Created dashboards and correlation queries to visualize Snort detections alongside endpoint and cloud telemetry.  

### 5. Threat Intelligence Integration
* Automated ingestion of IP/domain blacklists into Snort using scheduled scripts.  
* Mapped external threat intel against live traffic for proactive blocking.

---

## Results / Impact
* Achieved **>90% detection coverage** for common brute force, injection, and C2 traffic scenarios.  
* Reduced false positives by **40%** through precise rule tuning.  
* Demonstrated **Snort-to-SIEM integration**, enabling enterprise-grade incident correlation.  
* Validated detections against **real attack simulations** for credibility.  
* Delivered a **repeatable blueprint** for IDS/IPS deployment with enrichment.

---

## Key Takeaways
This project highlights my ability to:
* Engineer **custom IDS/IPS detections** aligned to real adversary techniques.  
* Balance **sensitivity vs. precision** through careful rule tuning.  
* Integrate detection systems into **enterprise SIEM workflows**.  
* Enhance network security posture with **automated threat intelligence enrichment**.  

The result was a hardened, measurable, and scalable Snort IDS/IPS implementation capable of detecting and blocking sophisticated threats in real time.
