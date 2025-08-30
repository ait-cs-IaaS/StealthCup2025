variable "team" { type = string }

variable "base_cidr" { type = string }
variable "internet_cidr" { type = string }
variable "images" { type = map(string) }
variable "team_images" {
  type = map(map(string))
}
variable "df_team_images" {
  type = map(map(string))
}
variable "flavors" { type = map(string) }
variable "vpc_id" { type = string }
variable "global_subnet_id" { type = string }
#variable "public_route_table_id" { type = string }
#variable "private_route_table_id" { type = string }
#variable "firewall_vpce" { type = string }
variable "infra_clients_rt" { type = string }

variable "ssh_key" {
  type = string
}

variable "target_availability_zone" {
  type = string
  default = "euc1-az3"
}

#variable "nlb_target_id" {
#  description = "The ID of the traffic mirror target"
#  type        = string
#}

#variable "ec2_mirror_filter_out" { type = string }
#variable "ec2_mirror_filter_in" { type = string }
variable "ec2_mirror_filter_all" { type = string }

variable "availability_zone" { type = string }

variable "allow_all_sg" { type = string }
variable "allow_mgmt_and_wazuh_sg" { type = string }
