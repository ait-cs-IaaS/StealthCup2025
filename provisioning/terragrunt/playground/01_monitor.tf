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
    var.allow_mgmt_and_wazuh_sg, aws_instance.monitoring_suricata
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