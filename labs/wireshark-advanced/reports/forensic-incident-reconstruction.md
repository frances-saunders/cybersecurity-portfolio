# Forensic Incident Reconstruction (Insider Exfil)

## Scenario
A developer allegedly exfiltrated source archives via HTTP and obfuscated DNS. We reconstruct the timeline using Wireshark.

## Steps
1. **Scope by suspect IP & timeframe**
   - Display filter: `ip.addr == 10.0.5.23 && (http || dns || tls)`
2. **Rebuild HTTP transactions**
   - File → Export Objects → HTTP (GUI) or:
   - `python3 scripts/file_carver_http.py -r <pcap> -o out/carved`
3. **Follow streams**
   - TCP stream analysis to connect logins/uploads to hostnames.
4. **DNS Indicators**
   - `dns && ip.src == 10.0.5.23` to inspect unusual high-entropy labels.
5. **Timeline**
   - Sort by frame.time, correlate with authentication events, proxies, and Snort/SIEM alerts.

## Evidence Pack
- Carved files hashes (SHA256)
- IOC list (domains, SNI, URIs)
- Stream transcripts & timestamps
