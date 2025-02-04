import maxminddb
import ipaddress

# Path to MaxMind GeoLite2 database
MMDB_PATH = "/var/lib/GeoIP/GeoLite2-Country.mmdb"
OUTPUT_FILE = "/etc/nftables/us_ips.txt"

# Open MaxMind database
with maxminddb.open_database(MMDB_PATH) as reader:
    with open(OUTPUT_FILE, "w") as outfile:
        # Loop through all possible IPv4 subnets
        for prefix in range(0, 256):
            subnet = f"{prefix}.0.0.0/8"  # Iterate through /8 ranges

            # Check if this subnet belongs to the US
            try:
                data = reader.get(str(ipaddress.ip_network(subnet).network_address))
                if data and data.get("country", {}).get("iso_code") == "US":
                    outfile.write(subnet + "\n")
            except Exception:
                continue  # Ignore errors in lookup

print(f"✅ Extracted US IPs saved to {OUTPUT_FILE}")

