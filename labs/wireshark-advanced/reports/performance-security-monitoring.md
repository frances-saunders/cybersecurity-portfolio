# Performance & Security Monitoring (Latency, ARP Spoof, MITM)

## Latency/Throughput
- Use `tcp_latency_report.py`: ```python3 scripts/tcp_latency_report.py -r <pcap> -o out/latency```
- Outputs per-flow handshake time, RTT medians, retransmission counts, zero-window events.

## ARP Spoof/MITM
- Heuristics:
- Multiple MACs claim the same IP (gratuitous ARPs).
- Abrupt gateway MAC changes mid-capture.
- Run detector: ```python3 scripts/arp_mitm_detector.py -r <pcap> -o out/arp_mitm.json```
- Cross-check in Wireshark with `arp.duplicate-address-detected`.

## Analyst Tips
- Validate asymmetric routing before concluding MITM.
- Use IO Graphs to visualize retransmissions (`tcp.analysis.retransmission`).

  
