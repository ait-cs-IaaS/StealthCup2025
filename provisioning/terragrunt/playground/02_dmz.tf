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