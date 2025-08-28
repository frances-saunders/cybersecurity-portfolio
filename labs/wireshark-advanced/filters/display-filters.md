# Wireshark Display Filters 

This cheat sheet focuses on expert-level workflows for **HTTP/2**, **TLS 1.3**, **DNS over HTTPS**, **malware C2 patterns**, **forensic reconstruction**, and **performance/security** triage.  
Fields vary slightly by Wireshark version—if a field isn’t recognized, open **Analyze ▸ Display Filter Expression…** and search by keyword (e.g., *ALPN*, *SNI*, *SAN*).

---

## 0) Quick Decode Hints (so filters actually match)
Some captures need hints so TLS/HTTP2 fields populate:

```bash
# Force port 443 to be dissected as TLS in tshark
tshark -r capture.pcap -d tcp.port==443,ssl -Y "tls"
````

In Wireshark GUI: **Decode As…** → add `TCP/443 → SSL`.

---

## 1) TLS 1.3 & HTTP/2 Deep Dive

### Identify TLS handshakes and metadata

```wireshark
tls
tls && tls.handshake.type == 1                      # ClientHello
tls && tls.handshake.type == 2                      # ServerHello
tls.handshake.extensions_server_name                # SNI present
tls.handshake.extensions_alpn_str contains "h2"     # ALPN negotiated HTTP/2
```

> **Note on TLS 1.3:** The record layer often shows `0x0303` (TLS 1.2) for TLS 1.3 traffic. Prefer supported/selected-version fields:

```wireshark
tls.handshake.version == 0x0304                     # Selected TLS 1.3 (if exposed)
tls.handshake.extensions_supported_version == 0x0304
tls.handshake.extensions_supported_versions         # (list) contains 0x0304
```

*(If your build lacks these exact names, search “supported\_versions” in the field picker.)*

### Check certificate/SAN vs SNI alignment

```wireshark
tls.handshake.extensions_server_name contains "example.com"
x509ce.dNSName contains "example.com"               # SubjectAltName dNSName entries
ssl.handshake.certificate                            # Legacy field; explore cert tree
```

### Confirm HTTP/2 over TLS (ALPN = h2)

```wireshark
tls.handshake.extensions_alpn_str contains "h2"
http2                                                # HTTP/2 frames present
```

### DNS over HTTPS (DoH) heuristics

```wireshark
http2 && tls.handshake.extensions_alpn_str contains "h2"
http2.header.name == ":path" && http2.header.value contains "/dns-query"
http2.header.name == ":authority" && http2.header.value contains "dns"
```

---

## 2) Encrypted Exfil / Anomaly Signals (No Decryption Needed)

**Side-channel indicators:**

```wireshark
# Small, periodic TLS records to same host (beaconing feel)
tls && frame.len < 400

# Rare or risky SNI patterns (dynamic DNS, new TLDs)
tls.handshake.extensions_server_name matches "(duckdns|no-ip|dynu|ddns|hopto|ddns\\.net|duckdns\\.org)"
tls.handshake.extensions_server_name matches ".*\\.(zip|top|xyz|best)$"

# HTTP/2 present from non-browser UAs (when plaintext is available)
http.user_agent matches "^(curl|Python-requests|Go-http-client)"
```

---

## 3) Malware / C2 Traffic Heuristics

**Plain HTTP beacons & loaders:**

```wireshark
http.request && http.user_agent matches "^(curl|Python-requests|Go-http-client)"
http.request.uri contains "gate.php" || http.request.uri contains "connect.php" || http.request.uri contains "update.php"
```

**SNI/DNS hints toward C2:**

```wireshark
tls.handshake.extensions_server_name matches "(duckdns|no-ip|dynu|ddns|hopto)"
dns.qry.name matches "(duckdns|no-ip|dynu|ddns|hopto)"
```

**Suspicious downloads (cleartext HTTP):**

```wireshark
http.response && (http.content_type contains "application/octet-stream" || http.content_type contains "application/x-dosexec")
http && frame contains 4d 5a                       # "MZ" magic in payload (PE)
```

---

## 4) Forensic Packet Analysis (Reconstruction)

**Scope by suspect host/time/protocol:**

```wireshark
ip.addr == 10.0.5.23 && (http || dns || tls)
```

**Follow streams & carve indicators:**

```wireshark
http.request || http.response
tcp.stream == 5                                     # Replace with actual stream ID
http.content_type contains "zip" || http contains "PK\x03\x04"
```

**SMB/Files (if applicable):**

```wireshark
smb2 || smb
smb2.filename                                      # Search in packet bytes/fields
```

**High-entropy DNS labels (exfil via DNS):**

```wireshark
dns && frame matches "[A-Za-z0-9]{40,}\\."
```

---

## 5) Performance & Reliability (Latency Triage)

**Handshake & retrans basics:**

```wireshark
tcp.flags.syn == 1 && tcp.flags.ack == 0            # SYNs (client hellos)
tcp.analysis.retransmission || tcp.analysis.out_of_order
tcp.analysis.zero_window || tcp.analysis.window_full
tcp.analysis.ack_rtt                                # Measured RTTs on ACKs
```

**Throughput constraints:**

```wireshark
tcp.window_size_value < 2048
tcp.options.sack_perm == 0                          # No SACK (older stacks)
```

**Server or network slowness symptoms:**

```wireshark
tcp.analysis.bytes_in_flight > 0 && tcp.analysis.retransmission
```

---

## 6) ARP Spoofing / MITM Indicators

**Conflicting IP→MAC mappings & duplicate IP alerts:**

```wireshark
arp.duplicate-address-detected
arp
```

**Gateway MAC changes during capture (heuristic):**

```wireshark
arp.opcode == 2 && (arp.src.proto_ipv4 matches "\\.1$|\\.254$")   # ARP replies from typical gateway IPs
```

Corroborate with **Endpoints/Conversations** (Statistics menu) to confirm multiple MACs claiming the same IP.

---

## 7) Handy Compound Filters

**HTTP/2 + TLS 1.3 + SNI present (browser-like session):**

```wireshark
tls && tls.handshake.extensions_alpn_str contains "h2"
&& (tls.handshake.version == 0x0304 || tls.handshake.extensions_supported_version == 0x0304 || tls.handshake.extensions_supported_versions)
&& tls.handshake.extensions_server_name
```

**DoH bursts from a single client:**

```wireshark
ip.src == 10.0.5.23
&& http2
&& (http2.header.name == ":path" && http2.header.value contains "/dns-query")
```

**Likely C2 beaconing (SNI + small TLS records to one host):**

```wireshark
tls && tls.handshake.extensions_server_name contains "example-c2"
&& frame.len < 400
```

---

## 8) Tshark One-Liners (CLI parity)

```bash
# List TLS sessions w/ SNI + ALPN (decode 443 as TLS)
tshark -r cap.pcap -d tcp.port==443,ssl -Y "tls" \
  -T fields -e frame.time -e ip.src -e ip.dst \
  -e tls.handshake.extensions_server_name -e tls.handshake.extensions_alpn_str

# Find HTTP/2 DoH requests
tshark -r cap.pcap -d tcp.port==443,ssl -Y 'http2 && frame contains "dns-query"' \
  -T fields -e frame.number -e ip.src -e ip.dst -e http2.streamid

# Retransmissions & RTTs
tshark -r cap.pcap -Y "tcp.analysis.retransmission || tcp.analysis.ack_rtt" \
  -T fields -e frame.time_epoch -e ip.src -e ip.dst -e tcp.stream -e tcp.analysis.ack_rtt
```

---

## 9) Color Rules (Optional Quality-of-Life)

In **View ▸ Coloring Rules…** you can add:

* `tcp.analysis.retransmission` → highlight in red
* `arp.duplicate-address-detected` → orange
* `http2` → light blue
* `tls && tls.handshake.extensions_alpn_str contains "h2"` → green

---

## 10) Tips & Pitfalls

* **TLS 1.3 detection:** If “supported\_versions” fields aren’t present, rely on **ALPN**, **SNI**, timing, and cipher suites to build confidence.
* **DoH identification:** Not all servers use `/dns-query`. Correlate with known DoH endpoints and traffic sizing/patterns.
* **Beaconing:** Look for **regular inter-arrival times** and small, repeated payload sizes to the **same SNI/IP**.
* **Context matters:** Always corroborate with host logs/SIEM and your Snort/Suricata detections.
