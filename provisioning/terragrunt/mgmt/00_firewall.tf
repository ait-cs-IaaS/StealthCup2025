# https://github.com/aws-samples/aws-network-firewall-terraform?tab=readme-ov-file
# https://github.com/aws-samples/aws-network-firewall-terraform/blob/main/firewall.tf
# https://aws.amazon.com/blogs/networking-and-content-delivery/deployment-models-for-aws-network-firewall-with-vpc-routing-enhancements/

resource "aws_subnet" "firewall_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.firewall_cidr
  availability_zone = var.availability_zone

  tags = {
    Name = "fw-subnet"
  }
}

#output "firewall_subnet_cidr" {
#  value = aws_subnet.firewall_subnet.cidr_block
#  description = "The Firewall subnet cidr block."
#}

# =====================
# === FIREWALL VCPE ===

output "firewall_vpce" {
  value = tolist([
      for sync_state in aws_networkfirewall_firewall.enterprise_firewall.firewall_status[0].sync_states : sync_state.attachment[0].endpoint_id
      if sync_state.attachment[0].subnet_id == aws_subnet.firewall_subnet.id
    ])[0]
  description = "Firewall VPCE for routing"
}

locals {
  firewall_vpce = tolist([
      for sync_state in aws_networkfirewall_firewall.enterprise_firewall.firewall_status[0].sync_states : sync_state.attachment[0].endpoint_id
      if sync_state.attachment[0].subnet_id == aws_subnet.firewall_subnet.id
    ])[0]
}

# =====================
# === CREATE ROUTES ===

## create firewalled route table that will later be used for clients
resource "aws_route_table" "firewalled" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "firewalled-route-table"
  }

}

output "infra_clients_route_table_id" {
  value = aws_route_table.firewalled.id
}

## create firewall route table that will be used for the firewall
resource "aws_route_table" "firewall" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "firewall-route-table"
  }
}

resource "aws_route_table_association" "firewall_association" {
  subnet_id      = aws_subnet.firewall_subnet.id
  route_table_id = aws_route_table.firewall.id 
}

# =====================
# === CREATE ROUTES ===

locals {
  team_cidr_blocks = flatten([
    for team in var.teams : [
      for offset in ["0", "16", "32", "48", "64"] :
        {
          team = team.name
          subnet_id = team.subnet_id
          cidr = "10.0.${team.subnet_id}.${offset}/28"
        }
    ]
  ])

  public_team_routes = {
    for index, entry in local.team_cidr_blocks :
    "${entry.team}-${index}" => entry
  }

  firewalled_team_routes = {
    for index, entry in local.team_cidr_blocks :
    "${entry.team}-${index}" => entry
  }
}

resource "aws_route" "override_ingress_route" {
  route_table_id         = aws_route_table.firewalled.id
  destination_cidr_block = var.internet_cidr
  vpc_endpoint_id        = local.firewall_vpce
}

resource "aws_route" "override_firewalled_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = var.internet_cidr
  vpc_endpoint_id        = local.firewall_vpce
}

resource "aws_route" "override_firewalled_df_route" {
  route_table_id         = aws_route_table.firewalled.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = local.firewall_vpce
}

resource "aws_route" "public_team_routes" {
  for_each = local.public_team_routes

  route_table_id         = aws_route_table.firewalled.id
  destination_cidr_block = each.value.cidr
  vpc_endpoint_id        = local.firewall_vpce

  depends_on = [aws_route_table.public_rt, aws_networkfirewall_rule_group.stateful_engine]
}

resource "aws_route" "firewalled_team_routes" {
  for_each = local.firewalled_team_routes

  route_table_id         =  aws_route_table.public_rt.id
  destination_cidr_block = each.value.cidr
  vpc_endpoint_id        = local.firewall_vpce

  depends_on = [aws_route_table.firewalled, aws_networkfirewall_rule_group.stateful_engine]
}

# ========================
# === CREATE FW POLICY ===

resource "aws_networkfirewall_firewall" "enterprise_firewall" {
  name                = "enterprisefirewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.enterprise_firewall_policy.arn
  vpc_id              = aws_vpc.main.id

  subnet_mapping {
    subnet_id = aws_subnet.firewall_subnet.id
  }

  tags = {
    Name   = "enterprise_firewall"
  }
}

resource "aws_networkfirewall_logging_configuration" "enterprise_firewall" {
  firewall_arn = aws_networkfirewall_firewall.enterprise_firewall.arn

  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.enterprise_firewall.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }

    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.enterprise_firewall_alerts.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
  }
}

resource "aws_cloudwatch_log_group" "enterprise_firewall" {
  name              = "/aws/network-firewall/enterprise-firewall"
  retention_in_days = 30  # Adjust retention period as needed

  tags = {
    Name = "enterprise-firewall-log-group"
  }
}

resource "aws_cloudwatch_log_group" "enterprise_firewall_alerts" {
  name              = "/aws/network-firewall/enterprise-firewall-alerts"
  retention_in_days = 30  # Adjust retention period as needed

  tags = {
    Name = "enterprise-firewall-alerts-log-group"
  }
}

resource "aws_networkfirewall_firewall_policy" "enterprise_firewall_policy" {
  name = "enterprisefirewallpolicy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful_engine.arn
      priority     = 10
    }
    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }
  }

  tags = {
    Name   = "enterprise_firewall_policy"
  }
}

# https://docs.aws.amazon.com/network-firewall/latest/APIReference/API_StatefulRule.html#networkfirewall-Type-StatefulRule-Action

locals {
  suricata_rules = [
{ direction = "FORWARD", action = "PASS", source = "10.0.1.0/24", destination = "10.0.1.8/32", sid = "1001", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.1.0/24", destination = "10.0.1.9/32", sid = "1002", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.1.128/28", destination = "10.0.1.8/32", sid = "1003", proto = "TCP", port = "22" },
{ direction = "FORWARD", action = "PASS", source = "10.0.1.128/28", destination = "10.0.1.9/32", sid = "1004", proto = "TCP", port = "22" },
{ direction = "ANY", action = "DROP", source = "10.0.1.0/24", destination = "10.0.0.0/24", sid = "1005", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.242.0/24", destination = "10.0.1.0/24", sid = "1006", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.1.11/32", destination = "8.8.8.8", sid = "1007", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.1.43/32", destination = "8.8.8.8", sid = "1008", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.1.0/28", destination = "10.0.1.16/28", sid = "1009", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.1.0/24", destination = "10.0.1.10/32", sid = "1010", proto = "TCP", port = "1514" },
{ direction = "FORWARD", action = "PASS", source = "10.0.1.0/24", destination = "10.0.1.10/32", sid = "1011", proto = "TCP", port = "1515" },
{ direction = "FORWARD", action = "PASS", source = "10.0.1.0/24", destination = "10.0.1.10/32", sid = "1012", proto = "TCP", port = "55000" },
{ direction = "FORWARD", action = "PASS", source = "10.0.1.0/24", destination = "10.0.1.11/32", sid = "1013", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.1.0/24", destination = "10.0.1.43/32", sid = "1014", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.1.11/32", destination = "10.0.1.43/32", sid = "1015", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.1.16/28", destination = "10.0.1.44/32", sid = "1016", proto = "TCP", port = "3389" },
{ direction = "FORWARD", action = "PASS", source = "10.0.1.32/28", destination = "10.0.1.48/28", sid = "1017", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.1.45/32", destination = "10.0.1.74/32", sid = "1018", proto = "UDP", port = "420" },
{ direction = "FORWARD", action = "PASS", source = "10.0.1.45/32", destination = "10.0.1.74/32", sid = "1019", proto = "TCP", port = "502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.1.45/32", destination = "10.0.1.74/32", sid = "1020", proto = "TCP", port = "1502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.1.48/28", destination = "10.0.1.64/28", sid = "1021", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.1.0/28", destination = "10.0.1.0/28", sid = "1022", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.1.16/28", destination = "10.0.1.16/28", sid = "1023", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.1.32/28", destination = "10.0.1.32/28", sid = "1024", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.1.48/28", destination = "10.0.1.48/28", sid = "1025", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.1.62/28", destination = "10.0.1.62/28", sid = "1026", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.1.32/28", destination = "0.0.0.0/0", sid = "1027", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.1.48/28", destination = "0.0.0.0/0", sid = "1028", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.1.64/28", destination = "0.0.0.0/0", sid = "1029", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.1.0/24", destination = "10.0.0.0/8", sid = "1030", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.2.0/24", destination = "10.0.2.8/32", sid = "1031", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.2.0/24", destination = "10.0.2.9/32", sid = "1032", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.2.128/28", destination = "10.0.2.8/32", sid = "1033", proto = "TCP", port = "22" },
{ direction = "FORWARD", action = "PASS", source = "10.0.2.128/28", destination = "10.0.2.9/32", sid = "1034", proto = "TCP", port = "22" },
{ direction = "ANY", action = "DROP", source = "10.0.2.0/24", destination = "10.0.0.0/24", sid = "1035", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.242.0/24", destination = "10.0.2.0/24", sid = "1036", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.2.11/32", destination = "8.8.8.8", sid = "1037", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.2.43/32", destination = "8.8.8.8", sid = "1038", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.2.0/28", destination = "10.0.2.16/28", sid = "1039", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.2.0/24", destination = "10.0.2.10/32", sid = "1040", proto = "TCP", port = "1514" },
{ direction = "FORWARD", action = "PASS", source = "10.0.2.0/24", destination = "10.0.2.10/32", sid = "1041", proto = "TCP", port = "1515" },
{ direction = "FORWARD", action = "PASS", source = "10.0.2.0/24", destination = "10.0.2.10/32", sid = "1042", proto = "TCP", port = "55000" },
{ direction = "FORWARD", action = "PASS", source = "10.0.2.0/24", destination = "10.0.2.11/32", sid = "1043", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.2.0/24", destination = "10.0.2.43/32", sid = "1044", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.2.11/32", destination = "10.0.2.43/32", sid = "1045", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.2.16/28", destination = "10.0.2.44/32", sid = "1046", proto = "TCP", port = "3389" },
{ direction = "FORWARD", action = "PASS", source = "10.0.2.32/28", destination = "10.0.2.48/28", sid = "1047", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.2.45/32", destination = "10.0.2.74/32", sid = "1048", proto = "UDP", port = "420" },
{ direction = "FORWARD", action = "PASS", source = "10.0.2.45/32", destination = "10.0.2.74/32", sid = "1049", proto = "TCP", port = "502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.2.45/32", destination = "10.0.2.74/32", sid = "1050", proto = "TCP", port = "1502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.2.48/28", destination = "10.0.2.64/28", sid = "1051", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.2.0/28", destination = "10.0.2.0/28", sid = "1052", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.2.16/28", destination = "10.0.2.16/28", sid = "1053", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.2.32/28", destination = "10.0.2.32/28", sid = "1054", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.2.48/28", destination = "10.0.2.48/28", sid = "1055", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.2.62/28", destination = "10.0.2.62/28", sid = "1056", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.2.32/28", destination = "0.0.0.0/0", sid = "1057", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.2.48/28", destination = "0.0.0.0/0", sid = "1058", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.2.64/28", destination = "0.0.0.0/0", sid = "1059", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.2.0/24", destination = "10.0.0.0/8", sid = "1060", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.3.0/24", destination = "10.0.3.8/32", sid = "1061", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.3.0/24", destination = "10.0.3.9/32", sid = "1062", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.3.128/28", destination = "10.0.3.8/32", sid = "1063", proto = "TCP", port = "22" },
{ direction = "FORWARD", action = "PASS", source = "10.0.3.128/28", destination = "10.0.3.9/32", sid = "1064", proto = "TCP", port = "22" },
{ direction = "ANY", action = "DROP", source = "10.0.3.0/24", destination = "10.0.0.0/24", sid = "1065", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.242.0/24", destination = "10.0.3.0/24", sid = "1066", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.3.11/32", destination = "8.8.8.8", sid = "1067", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.3.43/32", destination = "8.8.8.8", sid = "1068", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.3.0/28", destination = "10.0.3.16/28", sid = "1069", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.3.0/24", destination = "10.0.3.10/32", sid = "1070", proto = "TCP", port = "1514" },
{ direction = "FORWARD", action = "PASS", source = "10.0.3.0/24", destination = "10.0.3.10/32", sid = "1071", proto = "TCP", port = "1515" },
{ direction = "FORWARD", action = "PASS", source = "10.0.3.0/24", destination = "10.0.3.10/32", sid = "1072", proto = "TCP", port = "55000" },
{ direction = "FORWARD", action = "PASS", source = "10.0.3.0/24", destination = "10.0.3.11/32", sid = "1073", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.3.0/24", destination = "10.0.3.43/32", sid = "1074", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.3.11/32", destination = "10.0.3.43/32", sid = "1075", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.3.16/28", destination = "10.0.3.44/32", sid = "1076", proto = "TCP", port = "3389" },
{ direction = "FORWARD", action = "PASS", source = "10.0.3.32/28", destination = "10.0.3.48/28", sid = "1077", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.3.45/32", destination = "10.0.3.74/32", sid = "1078", proto = "UDP", port = "420" },
{ direction = "FORWARD", action = "PASS", source = "10.0.3.45/32", destination = "10.0.3.74/32", sid = "1079", proto = "TCP", port = "502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.3.45/32", destination = "10.0.3.74/32", sid = "1080", proto = "TCP", port = "1502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.3.48/28", destination = "10.0.3.64/28", sid = "1081", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.3.0/28", destination = "10.0.3.0/28", sid = "1082", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.3.16/28", destination = "10.0.3.16/28", sid = "1083", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.3.32/28", destination = "10.0.3.32/28", sid = "1084", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.3.48/28", destination = "10.0.3.48/28", sid = "1085", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.3.62/28", destination = "10.0.3.62/28", sid = "1086", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.3.32/28", destination = "0.0.0.0/0", sid = "1087", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.3.48/28", destination = "0.0.0.0/0", sid = "1088", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.3.64/28", destination = "0.0.0.0/0", sid = "1089", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.3.0/24", destination = "10.0.0.0/8", sid = "1090", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.4.0/24", destination = "10.0.4.8/32", sid = "1091", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.4.0/24", destination = "10.0.4.9/32", sid = "1092", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.4.128/28", destination = "10.0.4.8/32", sid = "1093", proto = "TCP", port = "22" },
{ direction = "FORWARD", action = "PASS", source = "10.0.4.128/28", destination = "10.0.4.9/32", sid = "1094", proto = "TCP", port = "22" },
{ direction = "ANY", action = "DROP", source = "10.0.4.0/24", destination = "10.0.0.0/24", sid = "1095", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.242.0/24", destination = "10.0.4.0/24", sid = "1096", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.4.11/32", destination = "8.8.8.8", sid = "1097", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.4.43/32", destination = "8.8.8.8", sid = "1098", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.4.0/28", destination = "10.0.4.16/28", sid = "1099", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.4.0/24", destination = "10.0.4.10/32", sid = "1100", proto = "TCP", port = "1514" },
{ direction = "FORWARD", action = "PASS", source = "10.0.4.0/24", destination = "10.0.4.10/32", sid = "1101", proto = "TCP", port = "1515" },
{ direction = "FORWARD", action = "PASS", source = "10.0.4.0/24", destination = "10.0.4.10/32", sid = "1102", proto = "TCP", port = "55000" },
{ direction = "FORWARD", action = "PASS", source = "10.0.4.0/24", destination = "10.0.4.11/32", sid = "1103", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.4.0/24", destination = "10.0.4.43/32", sid = "1104", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.4.11/32", destination = "10.0.4.43/32", sid = "1105", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.4.16/28", destination = "10.0.4.44/32", sid = "1106", proto = "TCP", port = "3389" },
{ direction = "FORWARD", action = "PASS", source = "10.0.4.32/28", destination = "10.0.4.48/28", sid = "1107", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.4.45/32", destination = "10.0.4.74/32", sid = "1108", proto = "UDP", port = "420" },
{ direction = "FORWARD", action = "PASS", source = "10.0.4.45/32", destination = "10.0.4.74/32", sid = "1109", proto = "TCP", port = "502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.4.45/32", destination = "10.0.4.74/32", sid = "1110", proto = "TCP", port = "1502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.4.48/28", destination = "10.0.4.64/28", sid = "1111", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.4.0/28", destination = "10.0.4.0/28", sid = "1112", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.4.16/28", destination = "10.0.4.16/28", sid = "1113", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.4.32/28", destination = "10.0.4.32/28", sid = "1114", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.4.48/28", destination = "10.0.4.48/28", sid = "1115", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.4.62/28", destination = "10.0.4.62/28", sid = "1116", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.4.32/28", destination = "0.0.0.0/0", sid = "1117", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.4.48/28", destination = "0.0.0.0/0", sid = "1118", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.4.64/28", destination = "0.0.0.0/0", sid = "1119", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.4.0/24", destination = "10.0.0.0/8", sid = "1120", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.5.0/24", destination = "10.0.5.8/32", sid = "1121", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.5.0/24", destination = "10.0.5.9/32", sid = "1122", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.5.128/28", destination = "10.0.5.8/32", sid = "1123", proto = "TCP", port = "22" },
{ direction = "FORWARD", action = "PASS", source = "10.0.5.128/28", destination = "10.0.5.9/32", sid = "1124", proto = "TCP", port = "22" },
{ direction = "ANY", action = "DROP", source = "10.0.5.0/24", destination = "10.0.0.0/24", sid = "1125", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.242.0/24", destination = "10.0.5.0/24", sid = "1126", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.5.11/32", destination = "8.8.8.8", sid = "1127", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.5.43/32", destination = "8.8.8.8", sid = "1128", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.5.0/28", destination = "10.0.5.16/28", sid = "1129", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.5.0/24", destination = "10.0.5.10/32", sid = "1130", proto = "TCP", port = "1514" },
{ direction = "FORWARD", action = "PASS", source = "10.0.5.0/24", destination = "10.0.5.10/32", sid = "1131", proto = "TCP", port = "1515" },
{ direction = "FORWARD", action = "PASS", source = "10.0.5.0/24", destination = "10.0.5.10/32", sid = "1132", proto = "TCP", port = "55000" },
{ direction = "FORWARD", action = "PASS", source = "10.0.5.0/24", destination = "10.0.5.11/32", sid = "1133", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.5.0/24", destination = "10.0.5.43/32", sid = "1134", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.5.11/32", destination = "10.0.5.43/32", sid = "1135", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.5.16/28", destination = "10.0.5.44/32", sid = "1136", proto = "TCP", port = "3389" },
{ direction = "FORWARD", action = "PASS", source = "10.0.5.32/28", destination = "10.0.5.48/28", sid = "1137", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.5.45/32", destination = "10.0.5.74/32", sid = "1138", proto = "UDP", port = "420" },
{ direction = "FORWARD", action = "PASS", source = "10.0.5.45/32", destination = "10.0.5.74/32", sid = "1139", proto = "TCP", port = "502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.5.45/32", destination = "10.0.5.74/32", sid = "1140", proto = "TCP", port = "1502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.5.48/28", destination = "10.0.5.64/28", sid = "1141", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.5.0/28", destination = "10.0.5.0/28", sid = "1142", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.5.16/28", destination = "10.0.5.16/28", sid = "1143", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.5.32/28", destination = "10.0.5.32/28", sid = "1144", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.5.48/28", destination = "10.0.5.48/28", sid = "1145", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.5.62/28", destination = "10.0.5.62/28", sid = "1146", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.5.32/28", destination = "0.0.0.0/0", sid = "1147", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.5.48/28", destination = "0.0.0.0/0", sid = "1148", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.5.64/28", destination = "0.0.0.0/0", sid = "1149", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.5.0/24", destination = "10.0.0.0/8", sid = "1150", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.6.0/24", destination = "10.0.6.8/32", sid = "1151", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.6.0/24", destination = "10.0.6.9/32", sid = "1152", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.6.128/28", destination = "10.0.6.8/32", sid = "1153", proto = "TCP", port = "22" },
{ direction = "FORWARD", action = "PASS", source = "10.0.6.128/28", destination = "10.0.6.9/32", sid = "1154", proto = "TCP", port = "22" },
{ direction = "ANY", action = "DROP", source = "10.0.6.0/24", destination = "10.0.0.0/24", sid = "1155", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.242.0/24", destination = "10.0.6.0/24", sid = "1156", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.6.11/32", destination = "8.8.8.8", sid = "1157", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.6.43/32", destination = "8.8.8.8", sid = "1158", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.6.0/28", destination = "10.0.6.16/28", sid = "1159", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.6.0/24", destination = "10.0.6.10/32", sid = "1160", proto = "TCP", port = "1514" },
{ direction = "FORWARD", action = "PASS", source = "10.0.6.0/24", destination = "10.0.6.10/32", sid = "1161", proto = "TCP", port = "1515" },
{ direction = "FORWARD", action = "PASS", source = "10.0.6.0/24", destination = "10.0.6.10/32", sid = "1162", proto = "TCP", port = "55000" },
{ direction = "FORWARD", action = "PASS", source = "10.0.6.0/24", destination = "10.0.6.11/32", sid = "1163", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.6.0/24", destination = "10.0.6.43/32", sid = "1164", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.6.11/32", destination = "10.0.6.43/32", sid = "1165", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.6.16/28", destination = "10.0.6.44/32", sid = "1166", proto = "TCP", port = "3389" },
{ direction = "FORWARD", action = "PASS", source = "10.0.6.32/28", destination = "10.0.6.48/28", sid = "1167", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.6.45/32", destination = "10.0.6.74/32", sid = "1168", proto = "UDP", port = "420" },
{ direction = "FORWARD", action = "PASS", source = "10.0.6.45/32", destination = "10.0.6.74/32", sid = "1169", proto = "TCP", port = "502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.6.45/32", destination = "10.0.6.74/32", sid = "1170", proto = "TCP", port = "1502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.6.48/28", destination = "10.0.6.64/28", sid = "1171", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.6.0/28", destination = "10.0.6.0/28", sid = "1172", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.6.16/28", destination = "10.0.6.16/28", sid = "1173", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.6.32/28", destination = "10.0.6.32/28", sid = "1174", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.6.48/28", destination = "10.0.6.48/28", sid = "1175", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.6.62/28", destination = "10.0.6.62/28", sid = "1176", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.6.32/28", destination = "0.0.0.0/0", sid = "1177", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.6.48/28", destination = "0.0.0.0/0", sid = "1178", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.6.64/28", destination = "0.0.0.0/0", sid = "1179", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.6.0/24", destination = "10.0.0.0/8", sid = "1180", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.7.0/24", destination = "10.0.7.8/32", sid = "1181", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.7.0/24", destination = "10.0.7.9/32", sid = "1182", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.7.128/28", destination = "10.0.7.8/32", sid = "1183", proto = "TCP", port = "22" },
{ direction = "FORWARD", action = "PASS", source = "10.0.7.128/28", destination = "10.0.7.9/32", sid = "1184", proto = "TCP", port = "22" },
{ direction = "ANY", action = "DROP", source = "10.0.7.0/24", destination = "10.0.0.0/24", sid = "1185", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.242.0/24", destination = "10.0.7.0/24", sid = "1186", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.7.11/32", destination = "8.8.8.8", sid = "1187", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.7.43/32", destination = "8.8.8.8", sid = "1188", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.7.0/28", destination = "10.0.7.16/28", sid = "1189", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.7.0/24", destination = "10.0.7.10/32", sid = "1190", proto = "TCP", port = "1514" },
{ direction = "FORWARD", action = "PASS", source = "10.0.7.0/24", destination = "10.0.7.10/32", sid = "1191", proto = "TCP", port = "1515" },
{ direction = "FORWARD", action = "PASS", source = "10.0.7.0/24", destination = "10.0.7.10/32", sid = "1192", proto = "TCP", port = "55000" },
{ direction = "FORWARD", action = "PASS", source = "10.0.7.0/24", destination = "10.0.7.11/32", sid = "1193", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.7.0/24", destination = "10.0.7.43/32", sid = "1194", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.7.11/32", destination = "10.0.7.43/32", sid = "1195", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.7.16/28", destination = "10.0.7.44/32", sid = "1196", proto = "TCP", port = "3389" },
{ direction = "FORWARD", action = "PASS", source = "10.0.7.32/28", destination = "10.0.7.48/28", sid = "1197", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.7.45/32", destination = "10.0.7.74/32", sid = "1198", proto = "UDP", port = "420" },
{ direction = "FORWARD", action = "PASS", source = "10.0.7.45/32", destination = "10.0.7.74/32", sid = "1199", proto = "TCP", port = "502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.7.45/32", destination = "10.0.7.74/32", sid = "1200", proto = "TCP", port = "1502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.7.48/28", destination = "10.0.7.64/28", sid = "1201", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.7.0/28", destination = "10.0.7.0/28", sid = "1202", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.7.16/28", destination = "10.0.7.16/28", sid = "1203", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.7.32/28", destination = "10.0.7.32/28", sid = "1204", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.7.48/28", destination = "10.0.7.48/28", sid = "1205", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.7.62/28", destination = "10.0.7.62/28", sid = "1206", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.7.32/28", destination = "0.0.0.0/0", sid = "1207", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.7.48/28", destination = "0.0.0.0/0", sid = "1208", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.7.64/28", destination = "0.0.0.0/0", sid = "1209", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.7.0/24", destination = "10.0.0.0/8", sid = "1210", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.8.0/24", destination = "10.0.8.8/32", sid = "1211", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.8.0/24", destination = "10.0.8.9/32", sid = "1212", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.8.128/28", destination = "10.0.8.8/32", sid = "1213", proto = "TCP", port = "22" },
{ direction = "FORWARD", action = "PASS", source = "10.0.8.128/28", destination = "10.0.8.9/32", sid = "1214", proto = "TCP", port = "22" },
{ direction = "ANY", action = "DROP", source = "10.0.8.0/24", destination = "10.0.0.0/24", sid = "1215", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.242.0/24", destination = "10.0.8.0/24", sid = "1216", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.8.11/32", destination = "8.8.8.8", sid = "1217", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.8.43/32", destination = "8.8.8.8", sid = "1218", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.8.0/28", destination = "10.0.8.16/28", sid = "1219", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.8.0/24", destination = "10.0.8.10/32", sid = "1220", proto = "TCP", port = "1514" },
{ direction = "FORWARD", action = "PASS", source = "10.0.8.0/24", destination = "10.0.8.10/32", sid = "1221", proto = "TCP", port = "1515" },
{ direction = "FORWARD", action = "PASS", source = "10.0.8.0/24", destination = "10.0.8.10/32", sid = "1222", proto = "TCP", port = "55000" },
{ direction = "FORWARD", action = "PASS", source = "10.0.8.0/24", destination = "10.0.8.11/32", sid = "1223", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.8.0/24", destination = "10.0.8.43/32", sid = "1224", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.8.11/32", destination = "10.0.8.43/32", sid = "1225", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.8.16/28", destination = "10.0.8.44/32", sid = "1226", proto = "TCP", port = "3389" },
{ direction = "FORWARD", action = "PASS", source = "10.0.8.32/28", destination = "10.0.8.48/28", sid = "1227", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.8.45/32", destination = "10.0.8.74/32", sid = "1228", proto = "UDP", port = "420" },
{ direction = "FORWARD", action = "PASS", source = "10.0.8.45/32", destination = "10.0.8.74/32", sid = "1229", proto = "TCP", port = "502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.8.45/32", destination = "10.0.8.74/32", sid = "1230", proto = "TCP", port = "1502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.8.48/28", destination = "10.0.8.64/28", sid = "1231", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.8.0/28", destination = "10.0.8.0/28", sid = "1232", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.8.16/28", destination = "10.0.8.16/28", sid = "1233", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.8.32/28", destination = "10.0.8.32/28", sid = "1234", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.8.48/28", destination = "10.0.8.48/28", sid = "1235", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.8.62/28", destination = "10.0.8.62/28", sid = "1236", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.8.32/28", destination = "0.0.0.0/0", sid = "1237", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.8.48/28", destination = "0.0.0.0/0", sid = "1238", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.8.64/28", destination = "0.0.0.0/0", sid = "1239", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.8.0/24", destination = "10.0.0.0/8", sid = "1240", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.9.0/24", destination = "10.0.9.8/32", sid = "1241", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.9.0/24", destination = "10.0.9.9/32", sid = "1242", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.9.128/28", destination = "10.0.9.8/32", sid = "1243", proto = "TCP", port = "22" },
{ direction = "FORWARD", action = "PASS", source = "10.0.9.128/28", destination = "10.0.9.9/32", sid = "1244", proto = "TCP", port = "22" },
{ direction = "ANY", action = "DROP", source = "10.0.9.0/24", destination = "10.0.0.0/24", sid = "1245", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.242.0/24", destination = "10.0.9.0/24", sid = "1246", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.9.11/32", destination = "8.8.8.8", sid = "1247", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.9.43/32", destination = "8.8.8.8", sid = "1248", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.9.0/28", destination = "10.0.9.16/28", sid = "1249", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.9.0/24", destination = "10.0.9.10/32", sid = "1250", proto = "TCP", port = "1514" },
{ direction = "FORWARD", action = "PASS", source = "10.0.9.0/24", destination = "10.0.9.10/32", sid = "1251", proto = "TCP", port = "1515" },
{ direction = "FORWARD", action = "PASS", source = "10.0.9.0/24", destination = "10.0.9.10/32", sid = "1252", proto = "TCP", port = "55000" },
{ direction = "FORWARD", action = "PASS", source = "10.0.9.0/24", destination = "10.0.9.11/32", sid = "1253", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.9.0/24", destination = "10.0.9.43/32", sid = "1254", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.9.11/32", destination = "10.0.9.43/32", sid = "1255", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.9.16/28", destination = "10.0.9.44/32", sid = "1256", proto = "TCP", port = "3389" },
{ direction = "FORWARD", action = "PASS", source = "10.0.9.32/28", destination = "10.0.9.48/28", sid = "1257", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.9.45/32", destination = "10.0.9.74/32", sid = "1258", proto = "UDP", port = "420" },
{ direction = "FORWARD", action = "PASS", source = "10.0.9.45/32", destination = "10.0.9.74/32", sid = "1259", proto = "TCP", port = "502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.9.45/32", destination = "10.0.9.74/32", sid = "1260", proto = "TCP", port = "1502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.9.48/28", destination = "10.0.9.64/28", sid = "1261", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.9.0/28", destination = "10.0.9.0/28", sid = "1262", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.9.16/28", destination = "10.0.9.16/28", sid = "1263", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.9.32/28", destination = "10.0.9.32/28", sid = "1264", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.9.48/28", destination = "10.0.9.48/28", sid = "1265", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.9.62/28", destination = "10.0.9.62/28", sid = "1266", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.9.32/28", destination = "0.0.0.0/0", sid = "1267", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.9.48/28", destination = "0.0.0.0/0", sid = "1268", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.9.64/28", destination = "0.0.0.0/0", sid = "1269", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.9.0/24", destination = "10.0.0.0/8", sid = "1270", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.10.0/24", destination = "10.0.10.8/32", sid = "1271", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.10.0/24", destination = "10.0.10.9/32", sid = "1272", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.10.128/28", destination = "10.0.10.8/32", sid = "1273", proto = "TCP", port = "22" },
{ direction = "FORWARD", action = "PASS", source = "10.0.10.128/28", destination = "10.0.10.9/32", sid = "1274", proto = "TCP", port = "22" },
{ direction = "ANY", action = "DROP", source = "10.0.10.0/24", destination = "10.0.0.0/24", sid = "1275", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.242.0/24", destination = "10.0.10.0/24", sid = "1276", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.10.11/32", destination = "8.8.8.8", sid = "1277", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.10.43/32", destination = "8.8.8.8", sid = "1278", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.10.0/28", destination = "10.0.10.16/28", sid = "1279", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.10.0/24", destination = "10.0.10.10/32", sid = "1280", proto = "TCP", port = "1514" },
{ direction = "FORWARD", action = "PASS", source = "10.0.10.0/24", destination = "10.0.10.10/32", sid = "1281", proto = "TCP", port = "1515" },
{ direction = "FORWARD", action = "PASS", source = "10.0.10.0/24", destination = "10.0.10.10/32", sid = "1282", proto = "TCP", port = "55000" },
{ direction = "FORWARD", action = "PASS", source = "10.0.10.0/24", destination = "10.0.10.11/32", sid = "1283", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.10.0/24", destination = "10.0.10.43/32", sid = "1284", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.10.11/32", destination = "10.0.10.43/32", sid = "1285", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.10.16/28", destination = "10.0.10.44/32", sid = "1286", proto = "TCP", port = "3389" },
{ direction = "FORWARD", action = "PASS", source = "10.0.10.32/28", destination = "10.0.10.48/28", sid = "1287", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.10.45/32", destination = "10.0.10.74/32", sid = "1288", proto = "UDP", port = "420" },
{ direction = "FORWARD", action = "PASS", source = "10.0.10.45/32", destination = "10.0.10.74/32", sid = "1289", proto = "TCP", port = "502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.10.45/32", destination = "10.0.10.74/32", sid = "1290", proto = "TCP", port = "1502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.10.48/28", destination = "10.0.10.64/28", sid = "1291", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.10.0/28", destination = "10.0.10.0/28", sid = "1292", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.10.16/28", destination = "10.0.10.16/28", sid = "1293", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.10.32/28", destination = "10.0.10.32/28", sid = "1294", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.10.48/28", destination = "10.0.10.48/28", sid = "1295", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.10.62/28", destination = "10.0.10.62/28", sid = "1296", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.10.32/28", destination = "0.0.0.0/0", sid = "1297", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.10.48/28", destination = "0.0.0.0/0", sid = "1298", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.10.64/28", destination = "0.0.0.0/0", sid = "1299", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.10.0/24", destination = "10.0.0.0/8", sid = "1300", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.11.0/24", destination = "10.0.11.8/32", sid = "1301", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.11.0/24", destination = "10.0.11.9/32", sid = "1302", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.11.128/28", destination = "10.0.11.8/32", sid = "1303", proto = "TCP", port = "22" },
{ direction = "FORWARD", action = "PASS", source = "10.0.11.128/28", destination = "10.0.11.9/32", sid = "1304", proto = "TCP", port = "22" },
{ direction = "ANY", action = "DROP", source = "10.0.11.0/24", destination = "10.0.0.0/24", sid = "1305", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.242.0/24", destination = "10.0.11.0/24", sid = "1306", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.11.11/32", destination = "8.8.8.8", sid = "1307", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.11.43/32", destination = "8.8.8.8", sid = "1308", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.11.0/28", destination = "10.0.11.16/28", sid = "1309", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.11.0/24", destination = "10.0.11.10/32", sid = "1310", proto = "TCP", port = "1514" },
{ direction = "FORWARD", action = "PASS", source = "10.0.11.0/24", destination = "10.0.11.10/32", sid = "1311", proto = "TCP", port = "1515" },
{ direction = "FORWARD", action = "PASS", source = "10.0.11.0/24", destination = "10.0.11.10/32", sid = "1312", proto = "TCP", port = "55000" },
{ direction = "FORWARD", action = "PASS", source = "10.0.11.0/24", destination = "10.0.11.11/32", sid = "1313", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.11.0/24", destination = "10.0.11.43/32", sid = "1314", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.11.11/32", destination = "10.0.11.43/32", sid = "1315", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.11.16/28", destination = "10.0.11.44/32", sid = "1316", proto = "TCP", port = "3389" },
{ direction = "FORWARD", action = "PASS", source = "10.0.11.32/28", destination = "10.0.11.48/28", sid = "1317", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.11.45/32", destination = "10.0.11.74/32", sid = "1318", proto = "UDP", port = "420" },
{ direction = "FORWARD", action = "PASS", source = "10.0.11.45/32", destination = "10.0.11.74/32", sid = "1319", proto = "TCP", port = "502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.11.45/32", destination = "10.0.11.74/32", sid = "1320", proto = "TCP", port = "1502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.11.48/28", destination = "10.0.11.64/28", sid = "1321", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.11.0/28", destination = "10.0.11.0/28", sid = "1322", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.11.16/28", destination = "10.0.11.16/28", sid = "1323", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.11.32/28", destination = "10.0.11.32/28", sid = "1324", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.11.48/28", destination = "10.0.11.48/28", sid = "1325", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.11.62/28", destination = "10.0.11.62/28", sid = "1326", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.11.32/28", destination = "0.0.0.0/0", sid = "1327", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.11.48/28", destination = "0.0.0.0/0", sid = "1328", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.11.64/28", destination = "0.0.0.0/0", sid = "1329", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.11.0/24", destination = "10.0.0.0/8", sid = "1330", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.12.0/24", destination = "10.0.12.8/32", sid = "1331", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.12.0/24", destination = "10.0.12.9/32", sid = "1332", proto = "UDP", port = "4789" },
{ direction = "FORWARD", action = "PASS", source = "10.0.12.128/28", destination = "10.0.12.8/32", sid = "1333", proto = "TCP", port = "22" },
{ direction = "FORWARD", action = "PASS", source = "10.0.12.128/28", destination = "10.0.12.9/32", sid = "1334", proto = "TCP", port = "22" },
{ direction = "ANY", action = "DROP", source = "10.0.12.0/24", destination = "10.0.0.0/24", sid = "1335", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.242.0/24", destination = "10.0.12.0/24", sid = "1336", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.12.11/32", destination = "8.8.8.8", sid = "1337", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.12.43/32", destination = "8.8.8.8", sid = "1338", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.12.0/28", destination = "10.0.12.16/28", sid = "1339", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.12.0/24", destination = "10.0.12.10/32", sid = "1340", proto = "TCP", port = "1514" },
{ direction = "FORWARD", action = "PASS", source = "10.0.12.0/24", destination = "10.0.12.10/32", sid = "1341", proto = "TCP", port = "1515" },
{ direction = "FORWARD", action = "PASS", source = "10.0.12.0/24", destination = "10.0.12.10/32", sid = "1342", proto = "TCP", port = "55000" },
{ direction = "FORWARD", action = "PASS", source = "10.0.12.0/24", destination = "10.0.12.11/32", sid = "1343", proto = "UDP", port = "53" },
{ direction = "FORWARD", action = "PASS", source = "10.0.12.0/24", destination = "10.0.12.43/32", sid = "1344", proto = "UDP", port = "53" },
{ direction = "ANY", action = "PASS", source = "10.0.12.11/32", destination = "10.0.12.43/32", sid = "1345", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.12.16/28", destination = "10.0.12.44/32", sid = "1346", proto = "TCP", port = "3389" },
{ direction = "FORWARD", action = "PASS", source = "10.0.12.32/28", destination = "10.0.12.48/28", sid = "1347", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.12.45/32", destination = "10.0.12.74/32", sid = "1348", proto = "UDP", port = "420" },
{ direction = "FORWARD", action = "PASS", source = "10.0.12.45/32", destination = "10.0.12.74/32", sid = "1349", proto = "TCP", port = "502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.12.45/32", destination = "10.0.12.74/32", sid = "1350", proto = "TCP", port = "1502" },
{ direction = "FORWARD", action = "PASS", source = "10.0.12.48/28", destination = "10.0.12.64/28", sid = "1351", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.12.0/28", destination = "10.0.12.0/28", sid = "1352", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.12.16/28", destination = "10.0.12.16/28", sid = "1353", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.12.32/28", destination = "10.0.12.32/28", sid = "1354", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.12.48/28", destination = "10.0.12.48/28", sid = "1355", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "PASS", source = "10.0.12.62/28", destination = "10.0.12.62/28", sid = "1356", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.12.32/28", destination = "0.0.0.0/0", sid = "1357", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.12.48/28", destination = "0.0.0.0/0", sid = "1358", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.12.64/28", destination = "0.0.0.0/0", sid = "1359", proto = "IP", port = "ANY" },
{ direction = "FORWARD", action = "DROP", source = "10.0.12.0/24", destination = "10.0.0.0/8", sid = "1360", proto = "IP", port = "ANY" },
{ direction = "ANY", action = "PASS", source = "10.0.0.0/24", destination = "0.0.0.0/0", sid = "1361", proto = "IP", port = "ANY" },
  ]
}

resource "aws_networkfirewall_rule_group" "stateful_engine" {
  capacity = 1000
  name     = "firewall"
  type     = "STATEFUL"
  rule_group {
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
    rule_variables {
      ip_sets {
        key = "VENDOREDR"
        ip_set {
          definition = ["3.121.187.176", "3.121.6.180", "3.121.238.86", "18.184.114.155", "18.194.8.224", "3.121.13.180", "3.69.184.79", "3.76.143.53", "3.77.82.22", "3.78.32.129", "3.123.240.202", "3.125.15.130", "18.158.187.80", "18.198.53.88", "35.156.219.65"]
        }
      }
    }
    rules_source {
      stateful_rule {
        action = "PASS"
        header {
          destination      = "10.0.242.0/24"
          destination_port = "4789"
          direction        = "FORWARD"
          protocol         = "UDP"
          source           = "10.0.0.0/24"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["1"]
        }
      }
      stateful_rule {
        action = "PASS"
        header {
          destination      = "$VENDOREDR"
          destination_port = "443"
          direction        = "FORWARD"
          protocol         = "TCP"
          source           = "ANY"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["2"]
        }
      }
      stateful_rule {
        action = "PASS"
        header {
          destination      = "ANY"
          destination_port = "ANY"
          direction        = "FORWARD"
          protocol         = "IP"
          source           = "10.0.242.0/24"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["3"]
        }
      }
      dynamic "stateful_rule" {
        for_each = local.suricata_rules
        content {
          action = stateful_rule.value["action"]
          header {
            destination      = stateful_rule.value["destination"]
            destination_port = stateful_rule.value["port"]
            direction        = stateful_rule.value["direction"]
            protocol         = stateful_rule.value["proto"]
            source           = stateful_rule.value["source"]
            source_port      = "ANY"
          }
          rule_option {
            keyword  = "sid"
            settings = [stateful_rule.value["sid"]]
          }
        }
      }
    }
  }
}

resource "random_string" "bucket_random_id" {
  length  = 5
  special = false
  upper   = false
}

resource "aws_s3_bucket" "anfw_flow_bucket" {
  bucket        = "network-firewall-flow-bucket-${random_string.bucket_random_id.id}"
  force_destroy = false
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.anfw_flow_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "anfw_flow_bucket_ownership_control" {
  bucket = aws_s3_bucket.anfw_flow_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "anfw_flow_bucket_public_access_block" {
  bucket = aws_s3_bucket.anfw_flow_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}