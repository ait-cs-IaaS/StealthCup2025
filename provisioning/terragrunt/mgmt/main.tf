resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "global_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.internet_cidr
  # map_public_ip_on_launch = true
  availability_zone = var.availability_zone

  tags = {
    Name = "internet-subnet"
  }
}

# Create a DHCP options set with Google Public DNS
resource "aws_vpc_dhcp_options" "custom_dhcp" {
  domain_name_servers = ["8.8.8.8", "8.8.4.4"]  # Google's DNS servers
  domain_name         = "stealth.ait.ac.at"
}

# Associate the DHCP options set with your VPC
resource "aws_vpc_dhcp_options_association" "custom_dhcp_association" {
  vpc_id          = aws_vpc.main.id
  dhcp_options_id = aws_vpc_dhcp_options.custom_dhcp.id
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# we use a fixed ip from now on
#resource "aws_eip" "nat_eip" {
#  domain          = "vpc"
#  tags = {
#    Name = "nat-gateway-eip"
#  }
#}

resource "aws_nat_gateway" "nat" {
  allocation_id = "eipalloc-0a0e4e8ad7bf89672" # aws_eip.nat_eip.id
  subnet_id     = aws_subnet.global_subnet.id

  tags = {
    Name = "nat-gateway"
  }
}

resource "aws_route_table" "private_rt" { # infra_clients
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "public-route-table"
  }

}

resource "aws_route" "override_public_df_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id        = aws_internet_gateway.igw.id
}

resource "aws_main_route_table_association" "public_association" {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.global_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "ssh_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    to_port     = 22
    from_port   = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    to_port     = 80
    from_port   = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    to_port     = 443
    from_port   = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ip forwarding per teams, this is now for 20 teams.
  ingress {
    to_port     = 2040
    from_port   = 2020
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssh-access-sg"
  }
}

resource "aws_security_group" "allow_mgmt_and_wazuh_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.242.0/24"]
  }

  ingress {
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # wazuh
  ingress {
    from_port   = 1514
    to_port     = 1515
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # wazuh
  ingress {
    from_port   = 1514
    to_port     = 1515
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # wazuh
  ingress {
    from_port   = 55000
    to_port     = 55000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # wazuh
  ingress {
    from_port   = 55000
    to_port     = 55000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.128/28"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.128/28"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.128/28"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.3.128/28"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.4.128/28"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.5.128/28"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.6.128/28"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.7.128/28"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.8.128/28"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.9.128/28"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.10.128/28"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.11.128/28"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.12.128/28"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.13.128/28"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.14.128/28"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.15.128/28"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.16.128/28"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-mgmt-and-wazuh-sg"
  }
}

resource "aws_security_group" "allow_all_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
  }

  tags = {
    Name = "allow-all-sg"
  }
}

output "allow_all_sg" {
  value = aws_security_group.allow_all_sg.id
}

output "allow_mgmt_and_wazuh_sg" {
  value = aws_security_group.allow_mgmt_and_wazuh_sg.id
}

resource "aws_ec2_traffic_mirror_filter" "all_traffic_filter" {
  description = "Traffic Mirror Filter for all traffic"
  tags = {
    Name = "all-traffic-filter"
  }
}

output "ec2_mirror_filter_all" {
  value = aws_ec2_traffic_mirror_filter.all_traffic_filter.id
}

resource "aws_ec2_traffic_mirror_filter_rule" "rule_in" {
  description              = "All Incoming Traffic"
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.all_traffic_filter.id
  destination_cidr_block   = "0.0.0.0/0"
  source_cidr_block        = "0.0.0.0/0"
  rule_number              = 1
  rule_action              = "accept"
  traffic_direction        = "ingress"
}

resource "aws_ec2_traffic_mirror_filter_rule" "rule_out" {
  description              = "All Outgoing Traffic"
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.all_traffic_filter.id
  destination_cidr_block   = "0.0.0.0/0"
  source_cidr_block        = "0.0.0.0/0"
  rule_number              = 1
  rule_action              = "accept"
  traffic_direction        = "egress"
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "global_subnet_id" {
  value = aws_subnet.global_subnet.id
}

output "private_route_table_id" {
  value = aws_route_table.private_rt.id
}

output "public_route_table_id" {
  value = aws_route_table.public_rt.id
}

#output "infra_clients_route_table_id" {
#  value = aws_route_table.private_rt.id
#}