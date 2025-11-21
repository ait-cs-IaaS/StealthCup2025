# subnets
resource "aws_subnet" "enterprise_server_subnet" {
  vpc_id     = var.vpc_id
  cidr_block = cidrsubnet(var.base_cidr, 4, 0)
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.team}_enterprise-server-subnet"
    Groups = "${var.team}"
  }
}

output "enterprise_server_subnet_cidr" {
  value = aws_subnet.enterprise_server_subnet.cidr_block
  description = "The enterprise server subnet cidr block."
}

resource "aws_subnet" "enterprise_client_subnet" {
  vpc_id     = var.vpc_id
  cidr_block = cidrsubnet(var.base_cidr, 4, 1)
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.team}_enterprise-client-subnet"
    Groups = "${var.team}"
  }
}

output "enterprise_client_subnet_cidr" {
  value = aws_subnet.enterprise_client_subnet.cidr_block
  description = "The enterprise client subnet cidr block."
}

resource "aws_route_table_association" "enterprise_association" {
  subnet_id      = aws_subnet.enterprise_server_subnet.id
  route_table_id = var.infra_clients_rt
}

resource "aws_route_table_association" "enterprise_client_association" {
  subnet_id      = aws_subnet.enterprise_client_subnet.id
  route_table_id = var.infra_clients_rt
}

resource "aws_instance" "enterprise_kali" {
  ami = lookup(
    lookup(var.team_images, var.team, {}), 
    "enterprise_kali", 
    var.df_team_images["build"]["enterprise_kali"]
  )
  instance_type   = var.flavors["enterprise_kali"]
  subnet_id       = aws_subnet.enterprise_client_subnet.id
  private_ip      = cidrhost(aws_subnet.enterprise_client_subnet.cidr_block, 14)
  security_groups = [var.allow_all_sg]
  #key_name        = "${var.team}_enterprise_kali_key"
  key_name        = var.ssh_key

  depends_on = [
    var.allow_all_sg
  ]
  lifecycle {
    ignore_changes = [
      security_groups,  # Avoids unnecessary EC2 recreations
    ]
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp2"
  }

  tags = {
    Name   = "${var.team}_enterprise_kali"
    Groups = "enterprise,hacker,${var.team}"
  }
}

# aws_instances
resource "aws_instance" "enterprise_domain_controller" {
  ami = lookup(
    lookup(var.team_images, var.team, {}), 
    "enterprise_domain_controller", 
    var.df_team_images["build"]["enterprise_domain_controller"]
  )
  instance_type   = var.flavors["enterprise_domain_controller"]
  subnet_id       = aws_subnet.enterprise_server_subnet.id
  private_ip      = cidrhost(aws_subnet.enterprise_server_subnet.cidr_block, 11)
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
    Name   = "${var.team}_enterprise_domain_controller"
    Groups = "enterprise,dc,windows,${var.team}"
  }
}

resource "aws_instance" "enterprise_file_server" {
  ami = lookup(
    lookup(var.team_images, var.team, {}), 
    "enterprise_file_server", 
    var.df_team_images["build"]["enterprise_file_server"]
  )
  instance_type   = var.flavors["enterprise_file_server"]
  subnet_id       = aws_subnet.enterprise_server_subnet.id
  private_ip      = cidrhost(aws_subnet.enterprise_server_subnet.cidr_block, 12)
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
    Name   = "${var.team}_enterprise_file_server"
    Groups = "enterprise,fs,windows,${var.team}"
  }
}

resource "aws_instance" "enterprise_client" {
  ami = lookup(
    lookup(var.team_images, var.team, {}), 
    "enterprise_client", 
    var.df_team_images["build"]["enterprise_client"]
  )
  instance_type   = var.flavors["enterprise_client"]
  subnet_id       = aws_subnet.enterprise_client_subnet.id
  private_ip      = cidrhost(aws_subnet.enterprise_client_subnet.cidr_block, 13)
  security_groups = [var.allow_all_sg]
  #key_name        = var.ssh_key
  user_data       = file("${path.module}/scripts/windows_ssh.ps1")

  depends_on = [
    var.allow_all_sg
  ]
  lifecycle {
    ignore_changes = [
      security_groups,  # Avoids unnecessary EC2 recreations
    ]
  }

  tags = {
    Name   = "${var.team}_enterprise_client"
    Groups = "enterprise,client,windows,${var.team}"
  }
}
