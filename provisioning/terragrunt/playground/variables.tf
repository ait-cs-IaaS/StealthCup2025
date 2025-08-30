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
variable "infra_clients_rt" { type = string }

variable "ssh_key" {
  type = string
}

variable "target_availability_zone" {
  type = string
  default = "euc1-az3"
}

variable "ec2_mirror_filter_all" { type = string }

variable "availability_zone" { type = string }

variable "allow_all_sg" { type = string }
variable "allow_mgmt_and_wazuh_sg" { type = string }
