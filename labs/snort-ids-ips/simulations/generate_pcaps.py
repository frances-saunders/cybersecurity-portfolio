#!/usr/bin/env python3
"""
Deterministically generate small PCAPs to exercise Snort rules.
No live traffic is emitted; packets are crafted.
"""

from scapy.all import *
import random

random.seed(1337)

def write_pcap(pkts, path):
    wrpcap(path, pkts)
    print(f"Wrote {path} ({len(pkts)} packets)")

# 1) nmap-portscan.pcap: SYNs to multiple ports (22,80,443,3389,...)
def pcap_portscan():
    src = "10.10.10.50"
    dst = "192.168.56.10"
    ports = [22, 80, 443, 3389, 445, 25, 110, 143, 8080, 8443]
    pkts = [IP(src=src, dst=dst)/TCP(sport=random.randint(1024,65535), dport=p, flags="S") for p in ports for _ in range(3)]
    write_pcap(pkts, "nmap-portscan.pcap")

# 2) sql-injection-attack.pcap: HTTP GET with union select
def pcap_sqli():
    src, dst = "10.10.10.60", "192.168.56.20"
    uri = "/search.php?q=1%20UNION/**/SELECT%20username,password%20FROM%20users"
    http = f"GET {uri} HTTP/1.1\r\nHost: demo.local\r\nUser-Agent: UA\r\n\r\n"
    pkt = IP(src=src,dst=dst)/TCP(sport=55555,dport=80,flags="PA")/Raw(load=http)
    write_pcap([pkt], "sql-injection-attack.pcap")

# 3) brute-force-ssh.pcap: Many SYNs to 22 (heuristic)
def pcap_bruteforce():
    src, dst = "10.10.10.70", "192.168.56.30"
    pkts = [IP(src=src,dst=dst)/TCP(sport=40000+i,dport=22,flags="S") for i in range(25)]
    write_pcap(pkts, "brute-force-ssh.pcap")

# 4) metasploit-malware-traffic.pcap: Suspicious UA + gate.php
def pcap_malware():
    src, dst = "10.10.10.80", "192.168.56.40"
    http = (
        "GET /gate.php?id=123 HTTP/1.1\r\n"
        "Host: c2.example.com\r\n"
        "User-Agent: Python-requests/2.31\r\n"
        "\r\n"
    )
    pkt = IP(src=src,dst=dst)/TCP(sport=50505,dport=80,flags="PA")/Raw(load=http)
    write_pcap([pkt], "metasploit-malware-traffic.pcap")

if __name__ == "__main__":
    pcap_portscan()
    pcap_sqli()
    pcap_bruteforce()
    pcap_malware()
