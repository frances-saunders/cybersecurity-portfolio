#!/usr/bin/env python3
"""
Check TLS endpoints for strong cipher/protocol support.
"""

import ssl, socket

def check_tls(host, port=443):
    ctx = ssl.create_default_context()
    with socket.create_connection((host, port)) as sock:
        with ctx.wrap_socket(sock, server_hostname=host) as ssock:
            print(f"{host}:{port} -> {ssock.version()}")

check_tls("example.com")
