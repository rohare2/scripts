#!/usr/bin/python3
# block_ET.py

import re
import subprocess
import time

LOG_FILE = "/var/log/suricata/fast.log"
BLOCKED_IPS = set()

def block_ip(ip_address):
    """Adds an IP address to the nftables set, only if it's not already blocked."""
    if ip_address not in BLOCKED_IPS:
        try:
            subprocess.run(["sudo", "nft", "add", "element", "inet", "suricata", "blocked_ips", "{", ip_address, "}"], check=True)
            BLOCKED_IPS.add(ip_address)
            print(f"Added IP to set: {ip_address}")
        except subprocess.CalledProcessError as e:
            print(f"Error adding IP to set {ip_address}: {e}")

def parse_logs():
    """Parses Suricata fast.log and adds IPs to the nftables set."""
    try:
        with open(LOG_FILE, "r") as f:
            for line in f:
                if "ET DROP" in line or "ET CINS" in line:
                    ip_match = re.search(r"{TCP} (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):\d+ ->", line)
                    if ip_match:
                        ip_address = ip_match.group(1)
                        block_ip(ip_address)

    except FileNotFoundError:
        print(f"Log file not found: {LOG_FILE}")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    while True:
        parse_logs()
        time.sleep(60)
