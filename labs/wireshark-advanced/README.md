# Wireshark Advanced Analysis Lab

## Overview

This lab showcases **expert-level packet analysis** using Wireshark and `tshark` across four focus areas:

* **Protocol Deep Dive**: Identify and validate HTTP/2, TLS 1.3, and DNS over HTTPS (DoH), including ALPN negotiation, SNI/certificate alignment, and encrypted-exfil indicators.
* **Malware Traffic Analysis**: Extract IoCs (SNI, DNS, hosts, URIs), characterize beaconing periodicity, and profile suspicious metadata without decryption.
* **Forensic Packet Analysis**: Reconstruct a simulated insider exfiltration event with stream following, file carving, and timeline correlation.
* **Performance & Security Monitoring**: Generate TCP latency and reliability metrics; detect ARP spoofing/MITM via heuristic signals.

All workflows are **reproducible** via `tshark`-based pipelines and small Python helpers. No plaintext secrets. No external services required.

---

## Folder Structure

```
labs/wireshark-advanced/
│
├── filters/
│   └── display-filters.md                  # Curated Wireshark display filters & analyst tips
│
├── reports/
│   ├── protocol-deep-dive.md               # HTTP/2, TLS 1.3, DoH methodology & checks
│   ├── malware-traffic-analysis.md         # IOC extraction & beaconing analysis
│   ├── forensic-incident-reconstruction.md # Insider exfil case walkthrough
│   ├── performance-security-monitoring.md  # Latency, ARP spoof, MITM detection
│   └── attack-coverage-matrix.csv          # ATT&CK mapping of analytic coverage
│
└── scripts/
│   ├── ioc_extractor.py                    # Extract SNI/DNS/HTTP URIs, ALPN, TLS ver, (best-effort) JA3
│   ├── tcp_latency_report.py               # Handshake time, RTT medians, retrans/zero-window counts
│   ├── arp_mitm_detector.py                # ARP conflict/gateway-MAC-change heuristics → JSON evidence
│   └── file_carver_http.py                 # Safe HTTP object carving + manifest with hashes
│
└── README.md
```

> Sample PCAPs exist in `labs/snort-ids-ips/simulations/` and can be used to run these analyses end-to-end.

---

## Prerequisites

* **Wireshark/tshark 3.4+** (`tshark -v`)
* **Python 3.9+**
* OS: Linux/macOS recommended; Windows supported via PowerShell and installed `tshark`

---

## Quickstart

### 1) IOC Extraction (works without TLS decryption)

```bash
# Use any capture; example uses the C2-like traffic sample from the Snort lab
python3 scripts/ioc_extractor.py \
  -r ../snort-ids-ips/simulations/metasploit-malware-traffic.pcap \
  -o out/iocs
# Outputs: out/iocs.json and out/iocs.csv (SNI, DNS, hosts, URIs, TLS ver, ALPN, (best-effort) JA3)
```

### 2) TCP Latency & Reliability

```bash
python3 scripts/tcp_latency_report.py \
  -r ../snort-ids-ips/simulations/nmap-portscan.pcap \
  -o out/latency
# Outputs: out/latency.csv and out/latency.md (per-flow handshake time, RTT median, retransmissions, zero-window)
```

### 3) ARP Spoof / MITM Heuristics

```bash
python3 scripts/arp_mitm_detector.py \
  -r your_capture.pcap \
  -o out/arp_mitm.json
# Outputs: JSON describing IP→MAC conflicts, gateway MAC changes, and confidence rating
```

### 4) Forensic HTTP File Carving

```bash
python3 scripts/file_carver_http.py \
  -r ../snort-ids-ips/simulations/sql-injection-attack.pcap \
  -o out/carved
# Outputs: carved files (size-guarded) and out/carved/manifest.json with SHA256 hashes
```

---

## What This Demonstrates (Expert-Level Outcomes)

**Protocol Deep Dive**

* Confirm **TLS 1.3** and **HTTP/2** using ALPN (`h2`) and handshake enumeration.
* Validate **SNI ↔ Certificate** alignment, SAN coverage, expiration, and EKU basics.
* Identify **DoH** patterns and co-existence anomalies (encrypted DNS where clear DNS is expected).
* Detect signs of **encrypted exfiltration** using side-channel indicators: record sizes, cadence, SNI risk signals, ALPN usage, and destination reputation.

**Malware Traffic Analysis**

* Extract **IoCs** systematically (SNI, DNS, hosts, URIs, ports, TLS metadata).
* Detect **beacon periodicity** via inter-arrival deltas and small-record cadence.
* Prioritize indicators using suspicious TLDs, dynamic DNS patterns, and rare SNI/ALPN combos.

**Forensic Packet Analysis**

* **Scope and timeline** a case by IP/timeframe; follow streams to attribute actions.
* **Carve evidence** (HTTP objects) with guardrails and produce hashed manifests.
* Produce an **evidence pack**: carved files, hashes, IoCs, stream transcripts, timeline.

**Performance & Security Monitoring**

* Generate **per-flow handshake/RTT** telemetry and retransmission/zero-window counts.
* Flag **ARP spoof/MITM** indicators and gateway MAC changes with confidence scoring.
* Correlate network symptoms with endpoint or proxy logs for root-cause analysis.

---

## Recommended Analyst Workflow

1. **Triage**

   * Run `ioc_extractor.py` on the capture to quickly surface destinations and protocols of interest.
2. **Deep Dive**

   * Validate ALPN/SNI/TLS versions; check for certificate misconfigurations.
3. **Threat Hunt**

   * Look for periodic flows, rare SNI, or DoH bursts. Pivot into Snort/SIEM if present.
4. **Forensics**

   * Reconstruct streams and export objects; hash and document findings.
5. **Performance/Security**

   * Generate latency and ARP/MITM reports; correlate with infrastructure telemetry.

---

## Display Filters (Cheat-Sheet)

See `filters/display-filters.md` for a curated list. Examples:

* TLS ClientHello/ServerHello: `tls && tls.handshake.type == 1` / `== 2`
* ALPN contains HTTP/2: `tls.handshake.extensions_alpn_str contains "h2"`
* SNI present: `tls.handshake.extensions_server_name`
* DoH heuristic: `http2 && frame contains "dns-query"`
* TCP retrans/zero-window: `tcp.analysis.retransmission || tcp.analysis.zero_window`
* ARP duplicates: `arp.duplicate-address-detected`

---

## ATT\&CK Coverage

`reports/attack-coverage-matrix.csv` maps these analyses to ATT\&CK techniques (e.g., T1041 Exfiltration Over C2 Channel, T1557 Adversary-in-the-Middle, T1071.001 Web Protocol C2).

---

## Security & Ethics

* Use only **sanitized** or lab-generated captures.
* Do **not** decrypt or analyze data without authorization.
* Keep SSL key logs and any sensitive artifacts segregated from production data.

---

## Troubleshooting

* If `tls.handshake.ja3` fields aren’t present in your build, the IOC extractor emits a deterministic **lite fingerprint** from TLS metadata.
* If `tshark` is missing on Windows, install Wireshark and add the `tshark.exe` directory to PATH.
* Large captures: run scripts with `-r <pcap>` after filtering or slice with `editcap` to reduce scope.

---

## Deliverables Produced

* IOC lists (`.json`, `.csv`)
* TCP latency reports (`.csv`, `.md`)
* ARP/MITM evidence (`.json`)
* Forensic carve set and manifest (`carved/*`, `manifest.json`)
* Analyst reports for each focus area (`reports/*.md`)
