resource "aws_subnet" "supervision_subnet" {
  vpc_id     = var.vpc_id
  cidr_block = cidrsubnet(var.base_cidr, 4, 3)
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.team}_supervision_subnet"
    Groups = "${var.team}"
  }
}

resource "aws_route_table_association" "supervision_association" {
  subnet_id      = aws_subnet.supervision_subnet.id
  route_table_id = var.infra_clients_rt
}

resource "aws_instance" "supervision_engineer_workstation" {
  ami = lookup(
    lookup(var.team_images, var.team, {}), 
    "supervision_engineer_workstation", 
    var.df_team_images["build"]["supervision_engineer_workstation"]
  )
  instance_type   = var.flavors["supervision_engineer_workstation"]
  subnet_id       = aws_subnet.supervision_subnet.id
  private_ip      = cidrhost(aws_subnet.supervision_subnet.cidr_block, 11)
  security_groups = [var.allow_all_sg]
  #key_name        = var.ssh_key
  #user_data = file("${path.module}/scripts/windows_ssh.ps1")

  root_block_device {
    volume_size = 35  # Original size in GiB
  }

  depends_on = [
    var.allow_all_sg
  ]
  lifecycle {
    ignore_changes = [
      security_groups,  # Avoids unnecessary EC2 recreations
    ]
  }

  tags = {
    Name = "${var.team}_supervision_engineer_workstation"
    Groups = "supervision,engineer_workstation,windows,${var.team}"
  }
}

resource "aws_ec2_traffic_mirror_session" "mirror_supervision_engineer" {
  network_interface_id     = aws_instance.supervision_engineer_workstation.primary_network_interface_id
  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.nlb_target.id
  traffic_mirror_filter_id = var.ec2_mirror_filter_all
  session_number           = 1

  depends_on = [
    aws_ec2_traffic_mirror_target.nlb_target
  ]
  tags = {
    Name = "${var.team}_mirror_supervision_engineer"
  }
}

resource "aws_instance" "supervision_scada" {
  ami = lookup(
    lookup(var.team_images, var.team, {}), 
    "supervision_scada", 
    var.df_team_images["build"]["supervision_scada"]
  )
  instance_type   = var.flavors["supervision_scada"]
  subnet_id       = aws_subnet.supervision_subnet.id
  private_ip      = cidrhost(aws_subnet.supervision_subnet.cidr_block, 12)
  security_groups = [var.allow_all_sg]
  key_name        = var.ssh_key
  
  depends_on = [
    var.allow_all_sg
  ]
  lifecycle {
    ignore_changes = [
      security_groups,  # Avoids unnecessary EC2 recreations
    ]
  }

  tags = {
    Name = "${var.team}_supervision_scada"
    Groups = "supervision,scada,linux,${var.team}"
  }
}

resource "aws_ec2_traffic_mirror_session" "mirror_supervision_scada" {
  network_interface_id     = aws_instance.supervision_scada.primary_network_interface_id
  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.nlb_target.id
  traffic_mirror_filter_id = var.ec2_mirror_filter_all
  session_number           = 1

  depends_on = [
    aws_ec2_traffic_mirror_target.nlb_target
  ]
  tags = {
    Name = "${var.team}_mirror_supervision_scada"
  }
}