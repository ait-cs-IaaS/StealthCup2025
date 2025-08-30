resource "aws_subnet" "dmz_subnet" {
  vpc_id     = var.vpc_id
  cidr_block = cidrsubnet(var.base_cidr, 4, 2)
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.team}_dmz-subnet"
  }
}

output "dmz_subnet_cidr" {
  value = aws_subnet.dmz_subnet.cidr_block
  description = "The dmz subnet cidr block."
}

resource "aws_route_table_association" "dmz_association" {
  subnet_id      = aws_subnet.dmz_subnet.id
  route_table_id = var.infra_clients_rt
}

#resource "aws_route" "new_dmz_route" {
#  route_table_id         = aws_route_table.dmz_route_table.id  # The already existing route table
#  destination_cidr_block = cidrsubnet(var.base_cidr, 4, 2)              # New route
#  vpc_endpoint_id        = var.firewall_vpce           # AWS Network Firewall
#}

#data "aws_route_table" "custom_route_table" {
#  vpc_id = var.vpc_id
#  filter {
#    name   = "tag:Name"
#    values = ["{var.team}_dmz-route-table"]  # Change this to match your route table name
#  }
#}

#resource "aws_route" "override_local_route" {
#  route_table_id         = data.aws_route_table.custom_route_table.id
#  destination_cidr_block = "10.0.0.0/16"  # Overriding the default local route
#  vpc_endpoint_id        = var.firewall_vpce  # Point to AWS Network Firewall
#}

resource "aws_instance" "dmz_domain_controller" {
  ami = lookup(
    lookup(var.team_images, var.team, {}), 
    "dmz_domain_controller", 
    var.df_team_images["build"]["dmz_domain_controller"]
  )
  instance_type   = var.flavors["dmz_domain_controller"]
  subnet_id       = aws_subnet.dmz_subnet.id
  private_ip      = cidrhost(aws_subnet.dmz_subnet.cidr_block, 11)
  security_groups = [var.allow_all_sg]
  #key_name        = var.ssh_key
  user_data = file("${path.module}/scripts/windows_ssh.ps1")

  depends_on = [
    var.allow_all_sg
  ]
  lifecycle {
    ignore_changes = [
      security_groups,  # Avoids unnecessary EC2 recreations
    ]
  }

  tags = {
    Name = "${var.team}_dmz_domain_controller"
    Groups = "dmz,dc,windows,${var.team}"
  }
}

resource "aws_ec2_traffic_mirror_session" "mirror_dmz_domain_controller" {
  network_interface_id     = aws_instance.dmz_domain_controller.primary_network_interface_id
  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.nlb_target.id
  traffic_mirror_filter_id = var.ec2_mirror_filter_all
  session_number           = 1

  depends_on = [
    aws_ec2_traffic_mirror_target.nlb_target
  ]
  tags = {
    Name = "${var.team}_mirror_dmz_domain_controller"
  }
}

resource "aws_instance" "dmz_jump" {
  ami = lookup(
    lookup(var.team_images, var.team, {}), 
    "dmz_jump", 
    var.df_team_images["build"]["dmz_jump"]
  )
  instance_type   = var.flavors["dmz_jump"]
  subnet_id       = aws_subnet.dmz_subnet.id
  private_ip      = cidrhost(aws_subnet.dmz_subnet.cidr_block, 12)
  security_groups = [var.allow_all_sg]
  #key_name        = var.ssh_key
  user_data = file("${path.module}/scripts/windows_ssh.ps1")

  depends_on = [
    var.allow_all_sg
  ]
  lifecycle {
    ignore_changes = [
      security_groups,  # Avoids unnecessary EC2 recreations
    ]
  }


  tags = {
    Name = "${var.team}_dmz_jump"
    Groups = "dmz,jump,windows,${var.team}"
  }
}

resource "aws_ec2_traffic_mirror_session" "mirror_dmz_jump" {
  network_interface_id     = aws_instance.dmz_jump.primary_network_interface_id
  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.nlb_target.id
  traffic_mirror_filter_id = var.ec2_mirror_filter_all
  session_number           = 1

  depends_on = [
    aws_ec2_traffic_mirror_target.nlb_target
  ]
  tags = {
    Name = "${var.team}_mirror_dmz_jump"
  }
}

resource "aws_instance" "dmz_historian" {
  ami = lookup(
    lookup(var.team_images, var.team, {}), 
    "dmz_historian", 
    var.df_team_images["build"]["dmz_historian"]
  )
  instance_type   = var.flavors["dmz_historian"]
  subnet_id       = aws_subnet.dmz_subnet.id
  private_ip      = cidrhost(aws_subnet.dmz_subnet.cidr_block, 13)
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
    Name = "${var.team}_dmz_historian"
    Groups = "dmz,historian,linux,${var.team}"
  }
}

resource "aws_ec2_traffic_mirror_session" "mirror_dmz_historian" {
  network_interface_id     = aws_instance.dmz_historian.primary_network_interface_id
  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.nlb_target.id
  traffic_mirror_filter_id = var.ec2_mirror_filter_all
  session_number           = 1

  depends_on = [
    aws_ec2_traffic_mirror_target.nlb_target
  ]
  tags = {
    Name = "${var.team}_mirror_dmz_historian"
  }
}