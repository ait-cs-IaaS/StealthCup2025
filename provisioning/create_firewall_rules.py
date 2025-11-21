import os

# Configuration
num_teams = 12  # Number of teams (adjust as needed)
management_network = "10.0.241.0/24"
private_networks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]

# Output file
rules_file = "aws_firewall.rules"
start = 1000

def gcount():
    global start 
    start += 1
    return start

def fw(direction = "ANY", action = "drop", source = "ANY", destination = "ANY", sid = None, proto = "IP", port = "ANY"):
    if sid is None:  # Ensure sid is only assigned at runtime
        sid = gcount()
    return f'{{ direction = "{direction}", action = "{action}", source = "{source}", destination = "{destination}", sid = "{sid}", proto = "{proto}", port = "{port}" }}'

def write_fw(f, direction = "ANY", action = "drop", source = "ANY", destination = "ANY", sid = None, proto = "IP", port = "ANY"):
    if sid is None:  # Ensure sid is only assigned at runtime
        sid = gcount()
    f.write(fw(direction = direction, action = action, source = source, destination = destination, sid = sid, proto = proto, port = port) + ",\n")


def generate_firewall_rules():
    with open(rules_file, "w") as f:
        
        # Block team-to-team traffic
        for x in range(1, num_teams + 1):
            write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.{x}.0/24", destination = f"10.0.{x}.8/32", proto = "UDP", port = "4789") # Allow VXLAN to suricata
            write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.{x}.0/24", destination = f"10.0.{x}.9/32", proto = "UDP", port = "4789") # Allow VXLAN to OT monitoring system
            write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.{x}.128/28", destination = f"10.0.{x}.8/32", proto = "TCP", port = "22") # Allow VXLAN health check
            write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.{x}.128/28", destination = f"10.0.{x}.9/32", proto = "TCP", port = "22") # Allow VXLAN health check
            write_fw(f, direction = "ANY", action = "DROP", source = f"10.0.{x}.0/24", destination = f"10.0.0.0/24") # deny BUILD to team and vice versa
            write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.242.0/24", destination = f"10.0.{x}.0/24") # allow mgmt to team
            write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.{x}.11/32", destination = f"8.8.8.8", proto="UDP", port="53") # allow DC to GOOGLE DNS
            write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.{x}.43/32", destination = f"8.8.8.8", proto="UDP", port="53") # allow OT-DC to GOOGLE DNS
            write_fw(f, direction = "ANY", action = "PASS", source = f"10.0.{x}.0/28", destination = f"10.0.{x}.16/28") # allow CLI to SRV
            write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.{x}.0/24", destination = f"10.0.{x}.10/32", proto = "TCP", port = "1514") # allow agent comm to Wazuh
            write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.{x}.0/24", destination = f"10.0.{x}.10/32", proto = "TCP", port = "1515") # allow agent enroll to Wazuh
            write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.{x}.0/24", destination = f"10.0.{x}.10/32", proto = "TCP", port = "55000") # allow agent enroll server API to Wazuh
            write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.{x}.0/24", destination = f"10.0.{x}.11/32", proto = "UDP", port = "53") # allow DC DNS from any
            write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.{x}.0/24", destination = f"10.0.{x}.43/32", proto = "UDP", port = "53") # allow DC DNS from any
            write_fw(f, direction = "ANY", action = "PASS", source = f"10.0.{x}.11/32", destination = f"10.0.{x}.43/32") # allow DC to DC
            write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.{x}.16/28", destination = f"10.0.{x}.44/32", proto = "TCP", port = "3389") # allow CLI to JUMP
            #write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.{x}.16/28", destination = f"10.0.{x}.45/32", proto = "TCP", port = "3000") # allow CLI to HIST
            write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.{x}.32/28", destination = f"10.0.{x}.48/28") # allow DMZ to SUPERVISION
            write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.{x}.45/32", destination = f"10.0.{x}.74/32", proto = "UDP", port = "420") # allow modbus from HIST to PLC
            write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.{x}.45/32", destination = f"10.0.{x}.74/32", proto = "TCP", port = "502") # allow modbus from HIST to PLC
            write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.{x}.45/32", destination = f"10.0.{x}.74/32", proto = "TCP", port = "1502") # allow modbus from HIST to PLC
            write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.{x}.48/28", destination = f"10.0.{x}.64/28") # allow SUPERVISION to CONTROL
            write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.{x}.0/28", destination = f"10.0.{x}.0/28") # allow to self
            write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.{x}.16/28", destination = f"10.0.{x}.16/28") # allow to self
            write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.{x}.32/28", destination = f"10.0.{x}.32/28") # allow to self
            write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.{x}.48/28", destination = f"10.0.{x}.48/28") # allow to self
            write_fw(f, direction = "FORWARD", action = "PASS", source = f"10.0.{x}.62/28", destination = f"10.0.{x}.62/28") # allow to self
            write_fw(f, direction = "FORWARD", action = "DROP", source = f"10.0.{x}.32/28", destination = f"0.0.0.0/0") # deny DMZ to all
            write_fw(f, direction = "FORWARD", action = "DROP", source = f"10.0.{x}.48/28", destination = f"0.0.0.0/0") # deny SUPERVISION to all
            write_fw(f, direction = "FORWARD", action = "DROP", source = f"10.0.{x}.64/28", destination = f"0.0.0.0/0") # deny CONTROL to all
            write_fw(f, direction = "FORWARD", action = "DROP", source = f"10.0.{x}.0/24", destination = f"10.0.0.0/8") # deny all other traffic to vpc

        write_fw(f, direction = "ANY", action = "PASS", source = f"10.0.0.0/24", destination = f"0.0.0.0/0") # allow BUILD TO ALL OTHER
        
        # Block outgoing traffic to other private networks (except management network)
        #block_rule = f'drop ip 10.0.0.0/8 -> [{", ".join(private_networks)}] ! [{management_network}] (msg:"Block outgoing private traffic (except mgmt)"; sid=200001; rev=1;)\n'
        #f.write(block_rule)

        # Allow management network full access
        # allow_rule = f'pass ip {management_network} any -> any any (msg:"Allow mgmt network to access all"; sid=300001; rev=1;)\n'
        #f.write(allow_rule)

    print(f"✅ Firewall rules generated: {rules_file}")

if __name__ == "__main__":
    generate_firewall_rules()