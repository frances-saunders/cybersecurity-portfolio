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
├── scripts/
│   ├── ioc_extractor.py                    # Extract SNI/DNS/HTTP URIs, ALPN, TLS ver, (best-effort) JA3
│   ├── tcp_latency_report.py               # Handshake time, RTT medians, retrans/zero-window counts
│   ├── arp_mitm_detector.py                # ARP conflict/gateway-MAC-change heuristics → JSON evidence
│   └── file_carver_http.py                 # Safe HTTP object carving + manifest with hashes
│
└── README.md
```

## Prerequisites

* **Wireshark/tshark 3.4+** (`tshark -v`)
* **Python 3.9+**
* OS: Linux/macOS recommended; Windows supported with `tshark` installed and on PATH

---

## Quickstart

### 1) IOC Extraction (works without TLS decryption)

```bash
python3 scripts/ioc_extractor.py \
  -r samples/c2-beacon-sample.pcap \
  -o out/iocs
# Produces: out/iocs.json and out/iocs.csv (SNI, DNS, hosts, URIs, TLS ver, ALPN, (best-effort) JA3)
```

### 2) TCP Latency & Reliability

```bash
python3 scripts/tcp_latency_report.py \
  -r samples/tls-http2-sample.pcap \
  -o out/latency
# Produces: out/latency.csv and out/latency.md (per-flow handshake time, RTT median, retrans, zero-window)
```

### 3) ARP Spoof / MITM Heuristics

```bash
python3 scripts/arp_mitm_detector.py \
  -r samples/any-lan-capture.pcap \
  -o out/arp_mitm.json
# Produces: JSON describing IP→MAC conflicts, gateway MAC changes, and confidence rating
```

### 4) Forensic HTTP File Carving

```bash
python3 scripts/file_carver_http.py \
  -r samples/insider-http-upload-sample.pcap \
  -o out/carved
# Produces: carved files (size-guarded) and out/carved/manifest.json with SHA256 hashes
```

---

## What This Demonstrates (Expert Outcomes)

**Protocol Deep Dive**

* Confirm **TLS 1.3** and **HTTP/2** using ALPN (`h2`) and handshake enumeration.
* Validate **SNI ↔ Certificate** alignment, SAN coverage, expiration, and EKU basics.
* Identify **DoH** patterns and co-existence anomalies (encrypted DNS where clear DNS is expected).
* Detect signs of **encrypted exfiltration** via side-channel indicators: record sizes, cadence, SNI risk, ALPN usage, and destination reputation.

**Malware Traffic Analysis**

* Systematic **IoC extraction** (SNI, DNS, hosts, URIs, ports, TLS metadata).
* **Beacon periodicity** via inter-arrival deltas and small-record cadence.
* Prioritize indicators using suspicious TLDs, dynamic DNS patterns, and rare SNI/ALPN combos.

**Forensic Packet Analysis**

* **Scope and timeline** a case by IP/timeframe; follow streams to attribute actions.
* **Carve evidence** (HTTP objects) with guardrails and produce hashed manifests.
* Deliver an **evidence pack**: carved files, hashes, IoCs, stream transcripts, timeline.

**Performance & Security Monitoring**

* Generate **per-flow handshake/RTT** telemetry and retransmission/zero-window counts.
* Flag **ARP spoof/MITM** indicators and gateway MAC changes with confidence scoring.
* Correlate network symptoms with endpoint/proxy logs for root-cause analysis.

---

## Display Filters (Cheat-Sheet)

See `filters/display-filters.md`. Examples:

* TLS ClientHello/ServerHello: `tls && tls.handshake.type == 1` / `== 2`
* ALPN contains HTTP/2: `tls.handshake.extensions_alpn_str contains "h2"`
* SNI present: `tls.handshake.extensions_server_name`
* DoH heuristic: `http2 && frame contains "dns-query"`
* TCP retrans/zero-window: `tcp.analysis.retransmission || tcp.analysis.zero_window`
* ARP duplicates: `arp.duplicate-address-detected`

---

## ATT\&CK Coverage

See `reports/attack-coverage-matrix.csv` for mappings (e.g., T1041 Exfiltration Over C2 Channel, T1557 Adversary-in-the-Middle, T1071.001 Web Protocol C2).

---

## Security & Ethics

* Use only **sanitized** or lab-generated captures.
* Do **not** decrypt or analyze data without authorization.
* Keep SSL key logs and any sensitive artifacts segregated from production data.

---

## Troubleshooting

* If `tls.handshake.ja3` fields aren’t present, the IOC extractor emits a deterministic **lite fingerprint** from TLS metadata.
* On Windows, install Wireshark and add `tshark.exe` to PATH.
* For large captures, pre-filter with `tshark -Y "<display-filter>" -w narrowed.pcap` or slice with `editcap`.
