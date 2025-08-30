variable "internet_cidr" { type = string }
variable "images" { type = map(string) }
variable "flavors" { type = map(string) }
variable "vpc_cidr" { type = string }
variable "firewall_cidr" { type = string }
variable "monitor_cidr" { type = string }
variable "availability_zone" { type = string }

variable "ssh_key" {
  type = string
}

variable "teams" {
  type = list(
    object({
      name      = string
      subnet_id = number
    })
  )
}