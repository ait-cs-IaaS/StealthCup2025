#resource "aws_instance" "enterprise_otids" {
#  ami             = var.images["otids"]
#  instance_type   = var.flavors["otids"]
#  subnet_id       = aws_subnet.monitor_subnet.id
#  private_ip      = cidrhost(aws_subnet.enterprise_server_subnet.cidr_block, 12)
#  security_groups = [var.allow_all_sg]
#  key_name        = var.ssh_key

#  depends_on = [
#    aws_security_group.allow_all_sg
#  ]
#  lifecycle {
#    ignore_changes = [
#      security_groups,  # Avoids unnecessary EC2 recreations
#    ]
#  }

#  tags = {
#    Name = "${var.team}_monitoring_otids"
#    Groups = "${var.team},ids,mirrortarget,internet"
#  }
#}

resource "aws_instance" "monitoring_suricata" {
  ami = lookup(
    lookup(var.team_images, var.team, {}), 
    "monitoring_suricata", 
    var.df_team_images["build"]["monitoring_suricata"]
  )
  instance_type   = var.flavors["suricata"]
  subnet_id       = aws_subnet.enterprise_server_subnet.id
  private_ip      = cidrhost(aws_subnet.enterprise_server_subnet.cidr_block, 9)
  security_groups = [var.allow_mgmt_and_wazuh_sg]
  key_name        = var.ssh_key

  depends_on = [
    var.allow_mgmt_and_wazuh_sg
  ]
  lifecycle {
    ignore_changes = [
      security_groups,  # Avoids unnecessary EC2 recreations
    ]
  }

  tags = {
    Name = "${var.team}_monitoring_suricata"
    Groups = "${var.team},suricata,nids,monitoring,linux"
  }

  root_block_device {
    volume_type = "gp3"      # General Purpose SSD
    volume_size = 40         # Size in GB
    delete_on_termination = true
  }
}

#resource "aws_ebs_volume" "suricata_pcap_store" {
#  availability_zone = aws_instance.monitoring_suricata.availability_zone
#  size              = 10  # Size in GB, adjust as needed
#  type              = "gp3"  # gp3 types provide up to 16,000 IOPS and 1,000 MB/s throughput
#  iops              = 16000  # Max IOPS for gp3 to ensure high performance
#  throughput        = 1000   # Max throughput in MB/s

##  tags = {
##    Name = "${var.team}_Suricata-PCAP-Storage"
##  }
#}

#resource "aws_volume_attachment" "suricata_pcap_store_attachment" {
#  device_name = "/dev/sdf"
#  volume_id   = aws_ebs_volume.suricata_pcap_store.id
#  instance_id = aws_instance.monitoring_suricata.id
##  force_detach = true
#}

resource "aws_instance" "monitoring_wazuh" {
  ami = lookup(
    lookup(var.team_images, var.team, {}), 
    "monitoring_wazuh", 
    var.df_team_images["build"]["monitoring_wazuh"]
  )
  instance_type   = var.flavors["elk"]
  subnet_id       = aws_subnet.enterprise_server_subnet.id
  private_ip      = cidrhost(aws_subnet.enterprise_server_subnet.cidr_block, 10)
  security_groups = [var.allow_mgmt_and_wazuh_sg]
  key_name        = var.ssh_key

  depends_on = [
    var.allow_mgmt_and_wazuh_sg
  ]
  lifecycle {
    ignore_changes = [
      security_groups,  # Avoids unnecessary EC2 recreations
    ]
  }

  tags = {
    Name = "${var.team}_monitoring_wazuh"
    Groups = "${var.team},wazuh,siem,monitoring,linux"
  }
  
  root_block_device {
    volume_type = "gp3"      # General Purpose SSD
    volume_size = 40         # Size in GB
    delete_on_termination = true
  }
}

#resource "aws_ec2_traffic_mirror_session" "mirror_monitoring_wazuh" {
#  network_interface_id     = aws_instance.monitoring_wazuh.primary_network_interface_id
#  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.nlb_target.id
#  traffic_mirror_filter_id = var.ec2_mirror_filter_all
#  session_number           = 1

#  depends_on = [
#    aws_ec2_traffic_mirror_target.nlb_target
#  ]
#  tags = {
#    Name = "${var.team}_mirror_monitoring_wazuh"
#  }
#}


resource "aws_instance" "monitoring_otids" {
  ami = lookup(
    lookup(var.team_images, var.team, {}), 
    "monitoring_otids", 
    var.df_team_images["build"]["monitoring_otids"]
  )
  instance_type   = var.flavors["otids"]
  key_name        = var.ssh_key
  user_data       = file("${path.module}/scripts/windows_ssh.ps1")

  lifecycle {
    ignore_changes = [
      security_groups,  # Avoids unnecessary EC2 recreations
    ]
  }

  root_block_device {
    volume_type = "gp3"      # General Purpose SSD
    volume_size = 201         # Size in GB
    delete_on_termination = true
  }

  # Attach primary network interface (NIC 1)
  network_interface {
    network_interface_id = aws_network_interface.monitoring_otids_primary_nic.id
    device_index         = 1
  }

  network_interface {
    network_interface_id = aws_network_interface.monitoring_otids_secondary_nic.id
    device_index         = 0
  }

  tags = {
    Name   = "${var.team}_monitoring_otids"
    Groups = "monitoring,otids,${var.team}"
  }
}


# Primary Network Interface (First NIC)
resource "aws_network_interface" "monitoring_otids_primary_nic" {
  subnet_id       = aws_subnet.enterprise_server_subnet.id
  private_ips     = [cidrhost(aws_subnet.enterprise_server_subnet.cidr_block, 7)]
  security_groups = [var.allow_mgmt_and_wazuh_sg]

  depends_on = [
    var.allow_mgmt_and_wazuh_sg
  ]
  tags = {
    Name = "${var.team}_monitoring_otids_1_primary_nic"
  }
}

resource "aws_network_interface" "monitoring_otids_secondary_nic" {
  subnet_id       = aws_subnet.enterprise_server_subnet.id
  private_ips     = [cidrhost(aws_subnet.enterprise_server_subnet.cidr_block, 8)]
  security_groups = [var.allow_mgmt_and_wazuh_sg]

  depends_on = [
    var.allow_mgmt_and_wazuh_sg
  ]
  tags = {
    Name = "${var.team}_monitoring_otids_1_secondary_nic"
  }
}

resource "aws_lb" "traffic_mirror_nlb" {
  name               = "${var.team}-traffic-mirror-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.lb_subnet.id]

  tags = {
    Name = "${var.team}-traffic-mirror-nlb"
  }
}

resource "aws_lb_target_group" "traffic_mirror_tg" {
  name     = "${var.team}-tmgt"
  port     = 4789
  protocol = "UDP"
  vpc_id   = var.vpc_id

  health_check {
    protocol            = "TCP"
    port                = "22"          # Using the same traffic port; alter if there's a specific non-listening port.
    interval            = 300              # Time between health checks in seconds
    healthy_threshold   = 10              # Number of consecutive health checks successes required to consider an unhealthy target healthy
    unhealthy_threshold = 10              # Number of consecutive health check failures required to consider a healthy target unhealthy
    timeout             = 60               # Timeout in seconds during which no response means a failed health check
  }

  tags = {
    Name = "${var.team}-tmgt"
  }
}

resource "aws_lb_target_group_attachment" "suricata_attachment" {
  target_group_arn = aws_lb_target_group.traffic_mirror_tg.arn
  target_id        = aws_instance.monitoring_suricata.id
  port             = 4789
}

#resource "aws_lb_target_group_attachment" "otids_attachment" {
#  target_group_arn = aws_lb_target_group.traffic_mirror_tg.arn
#  target_id        = aws_instance.monitoring_otids.id
#  port             = 4789
#}

resource "aws_lb_listener" "traffic_mirror_listener" {
  load_balancer_arn = aws_lb.traffic_mirror_nlb.arn
  port              = "4789"
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.traffic_mirror_tg.arn
  }
}

resource "aws_ec2_traffic_mirror_target" "nlb_target" {
  network_load_balancer_arn = aws_lb.traffic_mirror_nlb.arn

  tags = {
    Name = "${var.team}-nlb-tmt"
  }
}

resource "aws_subnet" "lb_subnet" {
  vpc_id     = var.vpc_id
  cidr_block = cidrsubnet(var.base_cidr, 4, 8)
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.team}-lb-subnet"
    Groups = "${var.team}"
  }
}