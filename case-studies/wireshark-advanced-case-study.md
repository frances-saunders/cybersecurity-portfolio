# Case Study: Wireshark Advanced Analysis Lab

## Problem / Challenge

Encrypted-by-default networks (TLS 1.3, HTTP/2, DNS over HTTPS) reduce payload visibility, making it difficult to: (1) validate protocol correctness (ALPN/SNI/cert alignment), (2) detect malware C2 and covert exfiltration without decryption, (3) reconstruct incidents for defensible evidence, and (4) tell performance faults from security events (e.g., retransmissions vs. ARP/MITM).
This project establishes a **repeatable, analyst-friendly workflow** using Wireshark/`tshark` and small Python utilities to produce actionable, auditable artifacts—**without plaintext secrets** or external services.

---

## Tools & Technologies

* **Wireshark / tshark (3.4+)** for protocol dissection, field extraction, and object export.
* **Python 3.9+** helper utilities:

  * `ioc_extractor.py` – metadata-based IOC extraction (SNI, DNS, hosts, URIs, ALPN, TLS ver, best-effort JA3\*).
  * `tcp_latency_report.py` – handshake time, RTT medians, retrans/zero-window counts per flow.
  * `arp_mitm_detector.py` – ARP conflict and gateway MAC change heuristics → JSON evidence.
  * `file_carver_http.py` – safe HTTP object carving + manifest with SHA256 hashes.
* **Sanitized lab PCAPs** stored locally (no external dependencies).

\* If JA3 fields are unavailable in the local Wireshark build, the extractor emits a deterministic “lite” fingerprint from TLS metadata.

---

## Actions Taken

### Protocol Deep Dive (HTTP/2, TLS 1.3, DoH)

* Identified TLS handshakes, **ALPN negotiation** (`h2`), and **SNI** with `tshark` field exports.
* Verified **certificate SAN ↔ SNI** alignment, expiration, and basic EKU.
* Detected **DNS over HTTPS** via HTTP/2 plus `/dns-query` path and header heuristics.
* Documented misconfig cases (e.g., SNI not present in SAN) with packet indices and remediation guidance.

**Representative commands**

```bash
# TLS + ALPN + SNI enumeration (treat 443 as TLS)
tshark -r tls-http2-sample.pcap -d tcp.port==443,ssl \
  -T fields -e frame.time -e ip.src -e ip.dst \
  -e tls.version -e tls.handshake.type \
  -e tls.handshake.extensions_alpn_str \
  -e tls.handshake.extensions_server_name

# Heuristic DoH discovery
tshark -r doh-sample.pcap -Y 'http2 && frame contains "dns-query"' \
  -T fields -e ip.src -e ip.dst -e http2.header.value
```

### Malware Traffic Analysis (Beaconing & IoCs)

* Extracted **IoCs** (SNI, DNS, hosts, URIs, ports, TLS metadata) using `ioc_extractor.py`.
* Measured **inter-arrival deltas** to expose periodic beaconing (10–60s).
* Prioritized risky indicators: suspicious TLDs (e.g., `.zip`, `.top`), DDNS patterns, rare SNI/ALPN combos, newly observed destinations.

**Representative command**

```bash
python3 scripts/ioc_extractor.py -r c2-beacon-sample.pcap -o out/iocs
```

### Forensic Packet Analysis (Insider Exfil Reconstruction)

* Scoped by user IP/time window; followed TCP streams; carved HTTP objects with size guards.
* Produced a **manifest with SHA256 hashes** and stream-aligned timestamps for a defensible evidence pack.
* Correlated uploads with DNS lookups and server responses to build a **timeline of exfiltration**.

**Representative command**

```bash
python3 scripts/file_carver_http.py -r insider-http-upload-sample.pcap -o out/carved
```

### Performance & Security Monitoring (Latency, ARP/MITM)

* Generated per-flow **handshake time** and **RTT medians**, plus retransmission/zero-window counts to separate congestion from security noise.
* Detected **ARP conflicts** and **gateway MAC changes** as MITM heuristics with confidence scoring.

**Representative commands**

```bash
python3 scripts/tcp_latency_report.py -r tls-http2-sample.pcap -o out/latency
python3 scripts/arp_mitm_detector.py -r any-lan-capture.pcap -o out/arp_mitm.json
```

---

## Results / Impact

* **Encrypted traffic visibility without decryption**: Reliable identification of TLS 1.3, HTTP/2, and DoH; surfaced SNI/cert anomalies and policy drift.
* **Rapid triage**: Structured IoC exports (CSV/JSON) enable swift correlation and enrichment.
* **Defensible forensics**: Carved artifacts with hashes and timestamps support internal review or legal processes.
* **Operational clarity**: Quantified handshake/RTT behavior; distinguished performance issues from security events; flagged ARP/MITM indicators with explainable evidence.

---

## Artifacts

* **Reports**

  * `reports/protocol-deep-dive.md` – methodology and protocol findings (HTTP/2, TLS 1.3, DoH).
  * `reports/malware-traffic-analysis.md` – IOC extraction and beacon periodicity results.
  * `reports/forensic-incident-reconstruction.md` – exfil timeline, carved evidence, and hashes.
  * `reports/performance-security-monitoring.md` – latency metrics and ARP/MITM heuristics.
  * `reports/attack-coverage-matrix.csv` – ATT\&CK mapping (e.g., T1041, T1071.001, T1557).
* **Scripted Outputs (examples)**

  * `out/iocs.csv`, `out/iocs.json` – destinations, SNI, DNS, URIs, ALPN/TLS ver, fingerprint.
  * `out/latency.csv`, `out/latency.md` – per-flow handshake/RTT, retrans/zero-window.
  * `out/arp_mitm.json` – conflicts, gateway MAC transitions, confidence.
  * `out/carved/*`, `out/carved/manifest.json` – recovered objects and SHA256 hashes.

---

## Key Takeaways

* **Metadata is powerful**: ALPN, SNI, timing, sizes, and destinations enable high-quality detection and validation in encrypted environments.
* **Evidence over anecdotes**: Automated carving, hashing, and timelines convert captures into defensible case files.
* **Performance vs. security**: Quant metrics prevent misdiagnosis; ARP/MITM heuristics add fast, explainable detection.
* **Repeatability & scale**: `tshark` pipelines and compact Python tools make senior-level analysis portable, auditable, and efficient.
