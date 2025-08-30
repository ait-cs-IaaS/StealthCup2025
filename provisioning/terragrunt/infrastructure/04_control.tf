resource "aws_subnet" "control_subnet" {
  vpc_id     = var.vpc_id
  cidr_block = cidrsubnet(var.base_cidr, 4, 4)
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.team}_control_subnet"
  }
}

resource "aws_route_table_association" "control_association" {
  subnet_id      = aws_subnet.control_subnet.id
  route_table_id = var.infra_clients_rt
}

resource "aws_instance" "control_plc_1" {
  ami = lookup(
    lookup(var.team_images, var.team, {}), 
    "control_plc_1", 
    var.df_team_images["build"]["control_plc_1"]
  )
  instance_type   = var.flavors["control_plc_1"]
  #subnet_id       = aws_subnet.control_subnet.id
  #private_ip      = cidrhost(aws_subnet.control_subnet.cidr_block, 10)
  #security_groups = [var.allow_mgmt_and_wazuh_sg]
  key_name        = var.ssh_key

  depends_on = [
    var.allow_mgmt_and_wazuh_sg
  ]
  lifecycle {
    ignore_changes = [
      security_groups,  # Avoids unnecessary EC2 recreations
    ]
  }

  # Attach primary network interface (NIC 1)
  network_interface {
    network_interface_id = aws_network_interface.control_plc_1_primary_nic.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.control_plc_1_secondary_nic.id
    device_index         = 1
  }

  tags = {
    Name = "${var.team}_control_plc_1"
    Groups = "control,scada,phoenix_contact,${var.team}"
  }
}

# Primary Network Interface (First NIC)
resource "aws_network_interface" "control_plc_1_primary_nic" {
  subnet_id       = aws_subnet.control_subnet.id
  private_ips     = [cidrhost(aws_subnet.control_subnet.cidr_block, 10)]
  security_groups = [var.allow_all_sg]

  depends_on = [
    var.allow_all_sg
  ]
  tags = {
    Name = "${var.team}_control_plc_1_primary_nic"
  }
}

resource "aws_network_interface" "control_plc_1_secondary_nic" {
  subnet_id       = aws_subnet.control_subnet.id
  private_ips     = [cidrhost(aws_subnet.control_subnet.cidr_block, 9)]
  security_groups = [var.allow_mgmt_and_wazuh_sg]

  depends_on = [
    var.allow_mgmt_and_wazuh_sg
  ]
  tags = {
    Name = "${var.team}_control_plc_1_secondary_nic"
  }
}

resource "aws_ec2_traffic_mirror_session" "mirror_control_plc_1" {
  network_interface_id     = aws_instance.control_plc_1.primary_network_interface_id
  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.nlb_target.id
  traffic_mirror_filter_id = var.ec2_mirror_filter_all
  session_number           = 1

  tags = {
    Name = "${var.team}_mirror_control_plc_1"
  }
  depends_on = [
    aws_ec2_traffic_mirror_target.nlb_target
  ]
}

#resource "aws_instance" "control_plc_2" {
#  ami = lookup(
#    lookup(var.team_images, var.team, {}), 
#    "control_plc_2", 
#    var.team_images["build"]["control_plc_2"]
#  )
#  instance_type   = var.flavors["control_plc_2"]
#  subnet_id       = aws_subnet.control_subnet.id
#  private_ip      = cidrhost(aws_subnet.control_subnet.cidr_block, 11)
#  security_groups = [var.allow_all_sg]
#  key_name        = var.ssh_key

#  depends_on = [
#    var.allow_all_sg
#  ]
#  lifecycle {
#    ignore_changes = [
#      security_groups,  # Avoids unnecessary EC2 recreations
#    ]
#  }

#  tags = {
#    Name = "${var.team}_control_plc_2"
#    Groups = "control,scada,phoenix_contact,${var.team}"
#  }
#}

#resource "aws_ec2_traffic_mirror_session" "mirror_control_plc_2" {
#  network_interface_id     = aws_instance.control_plc_2.primary_network_interface_id
#  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.eni_target.id
#  traffic_mirror_filter_id = var.ec2_mirror_filter_all
#  session_number           = 1

#  depends_on = [
#    aws_instance.monitoring_suricata
#  ]

#  tags = {
#    Name = "mirror_control_plc_2"
#  }
#}

#resource "aws_instance" "control_plc_2" {
#  ami             = var.images["ubuntu"]
#  instance_type   = var.flavors["server"]
#  subnet_id       = aws_subnet.control_subnet.id
#  private_ip      = cidrhost(aws_subnet.control_subnet.cidr_block, 12)
#  security_groups = [var.allow_all_sg]
#  key_name        = var.ssh_key

#  tags = {
#    Name = "control_plc_2"
#    Groups = "control,scada,abb,${var.team}"
#  }
#}
