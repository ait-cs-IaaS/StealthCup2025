terraform {
  backend "http" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

locals {
  indexed_teams = zipmap(
    range(length(var.teams)),
    var.teams
  )
}

module "mgmt" {
  source        = "./mgmt"
  internet_cidr = var.internet_cidr
  firewall_cidr = var.firewall_cidr
  monitor_cidr  = var.monitor_cidr
  vpc_cidr      = var.vpc_cidr
  images        = var.images
  flavors       = var.flavors
  ssh_key       = var.ssh_key
  teams         = var.teams
  availability_zone = "eu-central-1a"
}

module "infrastructure" {
  for_each = { for team in var.teams : team.name => team }

  source                 = "./infrastructure"
  internet_cidr          = var.internet_cidr
  global_subnet_id       = module.mgmt.global_subnet_id
  base_cidr              = cidrsubnet(var.vpc_cidr, 8, each.value.subnet_id)
  team                   = each.value.name
  images                 = var.images
  team_images            = var.team_images
  df_team_images         = var.df_team_images
  flavors                = var.flavors
  vpc_id                 = module.mgmt.vpc_id
  ec2_mirror_filter_all  = module.mgmt.ec2_mirror_filter_all
  allow_all_sg           = module.mgmt.allow_all_sg
  allow_mgmt_and_wazuh_sg = module.mgmt.allow_mgmt_and_wazuh_sg
  ssh_key                = var.ssh_key
  availability_zone      = "eu-central-1a"
  infra_clients_rt       = module.mgmt.infra_clients_route_table_id
}

module "playground" {
  for_each = { for team in var.playground_teams : team.name => team }

  source                 = "./playground"
  internet_cidr          = var.internet_cidr
  base_cidr              = cidrsubnet(var.vpc_cidr, 8, each.value.subnet_id)
  team                   = each.value.name
  images                 = var.images
  team_images            = var.team_images
  df_team_images         = var.df_team_images
  flavors                = var.flavors
  vpc_id                 = module.mgmt.vpc_id
  ec2_mirror_filter_all  = module.mgmt.ec2_mirror_filter_all
  allow_all_sg           = module.mgmt.allow_all_sg
  allow_mgmt_and_wazuh_sg = module.mgmt.allow_mgmt_and_wazuh_sg
  ssh_key                = var.ssh_key
  availability_zone      = "eu-central-1a"
  infra_clients_rt       = module.mgmt.private_route_table_id
}

output "enterprise_client_subnet_cidr" {
  value = { for team, infra in module.infrastructure : team => infra.enterprise_client_subnet_cidr }
}

output "enterprise_server_subnet_cidr" {
  value = { for team, infra in module.infrastructure : team => infra.enterprise_server_subnet_cidr }
}

output "dmz_subnet_cidr" {
  value = { for team, infra in module.infrastructure : team => infra.dmz_subnet_cidr }
}

output "enterprise_kali_ssh_key" {
  value      = { for team, infra in module.infrastructure : team => infra.enterprise_kali_private_key }
  sensitive  = true
}