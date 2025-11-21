variable "teams" {
  type = list(
    object({
      name      = string
      subnet_id = number
    })
  )
  default = [
    {
      name      = "team1"
      subnet_id = 1
    }
  ]
}

variable "playground_teams" {
  type = list(
    object({
      name      = string
      subnet_id = number
    })
  )
  default = [
    {
      name      = "team20"
      subnet_id = 20
    }
  ]
}

variable "images" {
  type = map(string)
  default = {
    ubuntu       = "ami-0a628e1e89aaedf80"
    windows_2022 = "ami-02c0a7e636abe4d52"
    windows_2025 = "ami-0841fa15ea134b052"
  }
}

variable "team_images" {
  type = map(any)
}

variable "df_team_images" {
  type = map(any)
  default = {
    build = { 
      monitoring_otids                = "ami-0d9ee3e3955d15472"
      enterprise_client                = "ami-024b43b0fa19b24e4" # setup_enterprise_client_v1.4.3
      enterprise_domain_controller     = "ami-0ae684e1fc8647fa7" # setup_enterprise_domain_controller_v1.4.4
      enterprise_file_server           = "ami-03a50b9c9dd45c5c6" # setup_enterprise_file_server_v1.4.3
      dmz_jump                         = "ami-05e55a1dac7e89682" # setup_dmz_jump_v1.4.3
      dmz_domain_controller            = "ami-05ccfae647df2378b" # setup_dmz_domain_controller_v1.4.3
      dmz_historian                    = "ami-04b6aea0b54b00cf3" # team1_dmz_historian-20250228-0934-i-08e34800a6e54141d
      monitoring_suricata              = "ami-0a628e1e89aaedf80" # ubuntu
      supervision_scada                = "ami-0d45d272d496af89d" # team1_supervision_scada-20250228-0934-i-08617b5db70d0929d
      supervision_engineer_workstation = "ami-0e7a077a47b9ecce8" # team1_supervision_engineer_workstation-20250228-0934-i-014a5feab77aa8f71
      monitoring_wazuh                 = "ami-0a628e1e89aaedf80" # ubuntu
      enterprise_kali                  = "ami-07ec79fa94e8e0dae" # "ami-093d1ceb3279619b0" # original 
      control_plc_1                    = "ami-035b5e540fde53ef6" # team1_control_plc_1-20250228-0934-i-0b000137a0a5da838
    }
  }
}

variable "flavors" {
  type = map(string)
  default = {
    elk                                 = "t3.xlarge"
    suricata                            = "c5n.xlarge" # consider things like "m5.4xlarge" for high perf
    otids                              = "c5.xlarge" # consider things like "m5.4xlarge" for high perf
    supervision_scada                   = "t3.large"
    supervision_engineer_workstation    = "t3.large"
    enterprise_kali                     = "t3.large"
    enterprise_client                   = "t3.large"
    enterprise_file_server              = "t3.large"
    enterprise_domain_controller        = "t3.large"
    dmz_jump                            = "t3.large"
    dmz_domain_controller               = "t3.large"
    dmz_historian                       = "t3.large"
    control_plc_1                       = "t3.large"
    mgmt                                = "t3.large"
  }
}

variable "monitor_cidr" {
  type    = string
  default = "10.0.241.0/24"
}

variable "internet_cidr" {
  type    = string
  default = "10.0.242.0/24"
}

variable "firewall_cidr" {
  type    = string
  default = "10.0.243.0/24"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "ssh_key" {
  type = string
  default = "stealthcup" # "stealthcup_rsa"
}
