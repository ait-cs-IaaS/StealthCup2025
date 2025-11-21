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