# Protocol Deep Dive: HTTP/2, TLS 1.3, and DNS over HTTPS

## Objectives
- Positively identify HTTP/2 and TLS 1.3 sessions.
- Validate ALPN negotiation and SNI/cert alignment.
- Detect DNS over HTTPS endpoints and flag misconfigurations.
- Highlight encrypted exfiltration risks and how to spot them without decryption.

## Method (Repeatable)
1. **Identify TLS sessions**
   - `tshark -r <pcap> -Y "tls" -T fields -e frame.time -e ip.src -e ip.dst -e tls.handshake.type -e tls.version -e tls.handshake.extensions_alpn_str -E header=y -E separator=,`
2. **Check SNI vs certificate CN/SAN**
   - Navigate to a ServerHello → Certificates in Wireshark; verify SAN contains SNI host.
   - Red flags: expired cert, CN/SAN mismatch, weak signature, wrong EKU.
3. **Confirm HTTP/2 (ALPN = h2)**
   - `tshark -r <pcap> -Y 'tls.handshake.extensions_alpn_str contains "h2"' -T fields -e ip.src -e ip.dst`
4. **Find DoH**
   - Heuristics: HTTP/2 + path `/dns-query` or known DoH hosts.
   - `tshark -r <pcap> -Y 'http2 && frame contains "dns-query"' -T fields -e ip.src -e ip.dst -e http2.header.value`
5. **Spotting encrypted exfil**
   - Indicators: high-rate small TLS records, regular beaconing intervals, SNI to newly-registered or DDNS, large POSTs to atypical paths (if decrypted), or DoH with unusually large/rapid queries.

## Analyst Notes
- You can detect a lot **without** decryption: ALPN, SNI, JA3/JA3S (if available), timing, sizes, and destinations are powerful.
- If you control endpoints, enable SSLKEYLOGFILE for lawful decryption during testing; keep keys segregated from production data.
