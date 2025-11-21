
# Associate the Elastic IP with the instance
resource "aws_eip_association" "mgmt_eip_assoc" {
  instance_id   = aws_instance.mgmt.id
  allocation_id = "eipalloc-0f1a571fb1733a190" # aws_eip.mgmt_ip.id
}

resource "aws_instance" "mgmt" {
  ami           = var.images["ubuntu"]
  instance_type = var.flavors["mgmt"]
  subnet_id     = aws_subnet.global_subnet.id
  vpc_security_group_ids = [aws_security_group.ssh_sg.id]
  depends_on      = [aws_internet_gateway.igw, aws_security_group.ssh_sg]

  #associate_public_ip_address = false # fixed IP
  key_name                    = var.ssh_key

  user_data = <<-EOF
    #!/bin/bash
    set -eux

    # Enable IP forwarding
    echo "net.ipv4.ip_forward = 1" | tee -a /etc/sysctl.conf
    sysctl -p

    # Configure iptables rules for forwarding
    iptables -t nat -A PREROUTING -p tcp --dport 2020 -j DNAT --to-destination 10.0.0.30:22
    iptables -t nat -A PREROUTING -p tcp --dport 2021 -j DNAT --to-destination 10.0.1.30:22
    iptables -t nat -A PREROUTING -p tcp --dport 2022 -j DNAT --to-destination 10.0.2.30:22
    iptables -t nat -A PREROUTING -p tcp --dport 2023 -j DNAT --to-destination 10.0.3.30:22
    iptables -t nat -A PREROUTING -p tcp --dport 2024 -j DNAT --to-destination 10.0.4.30:22
    iptables -t nat -A PREROUTING -p tcp --dport 2025 -j DNAT --to-destination 10.0.5.30:22
    iptables -t nat -A PREROUTING -p tcp --dport 2026 -j DNAT --to-destination 10.0.6.30:22
    iptables -t nat -A PREROUTING -p tcp --dport 2027 -j DNAT --to-destination 10.0.7.30:22
    iptables -t nat -A PREROUTING -p tcp --dport 2028 -j DNAT --to-destination 10.0.8.30:22
    iptables -t nat -A PREROUTING -p tcp --dport 2029 -j DNAT --to-destination 10.0.9.30:22
    iptables -t nat -A PREROUTING -p tcp --dport 2030 -j DNAT --to-destination 10.0.10.30:22
    iptables -t nat -A PREROUTING -p tcp --dport 2031 -j DNAT --to-destination 10.0.11.30:22
    iptables -t nat -A PREROUTING -p tcp --dport 2032 -j DNAT --to-destination 10.0.12.30:22
    iptables -t nat -A PREROUTING -p tcp --dport 2033 -j DNAT --to-destination 10.0.13.30:22
    iptables -t nat -A PREROUTING -p tcp --dport 2034 -j DNAT --to-destination 10.0.14.30:22
    iptables -t nat -A PREROUTING -p tcp --dport 2035 -j DNAT --to-destination 10.0.15.30:22
    iptables -t nat -A PREROUTING -p tcp --dport 2036 -j DNAT --to-destination 10.0.16.30:22
    iptables -t nat -A PREROUTING -p tcp --dport 2037 -j DNAT --to-destination 10.0.17.30:22
    iptables -t nat -A PREROUTING -p tcp --dport 2038 -j DNAT --to-destination 10.0.18.30:22
    iptables -t nat -A PREROUTING -p tcp --dport 2039 -j DNAT --to-destination 10.0.19.30:22
    iptables -t nat -A PREROUTING -p tcp --dport 2040 -j DNAT --to-destination 10.0.20.30:22
    iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE

    # Install iptables-persistent to persist rules across reboots (for Ubuntu/Debian)
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y iptables-persistent

    # Save iptables rules
    netfilter-persistent save
    netfilter-persistent reload

    # Ensure iptables rules are applied on reboot
    echo "@reboot root iptables-restore < /etc/iptables/rules.v4" | tee -a /etc/crontab
  EOF

  tags = {
    Name = "mgmt"
    Groups = "mgmthost"
  }
}

resource "aws_ebs_volume" "mgmt_pcap_store" {
  availability_zone = aws_instance.mgmt.availability_zone
  size              = 1000  # Size in GB, adjust as needed
  type              = "gp3"  # gp3 types provide up to 16,000 IOPS and 1,000 MB/s throughput
  iops              = 16000  # Max IOPS for gp3 to ensure high performance
  throughput        = 1000   # Max throughput in MB/s

  tags = {
    Name = "mgmt-PCAP-Storage"
  }
}

resource "aws_volume_attachment" "mgmt_pcap_store_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.mgmt_pcap_store.id
  instance_id = aws_instance.mgmt.id
#  force_detach = true
}

#resource "aws_eip" "mgmt_eip" {
#  domain          = "vpc"
#  instance        = aws_instance.mgmt.id
#  depends_on      = [aws_internet_gateway.igw]
#}

#output "mgmt_eip" {
#  value = aws_eip.mgmt_eip.public_ip
#}
