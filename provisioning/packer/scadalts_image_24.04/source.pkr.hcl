# Sources

## Build Hosts
#source "openstack" "builder" {
#  flavor                  = "${var.flavor}"
#  floating_ip_network     = "${var.floating_ip_pool}"
#  image_name              = "${var.timestamp_image ? replace(format("%s-%s", var.image_name, timestamp()), ":", "-") : var.image_name}"
#  networks              = ["${var.network}"]
#  security_groups         = "${var.security_group}"
#  ssh_ip_version          = "4"
#  ssh_username            = "${var.build_user}"
#  # ports                   = ["c2d25575-7969-48af-8954-24f7532e637e"]
#
#  source_image_filter {
#    filters {
#      name = "${var.base_image}"
#    }
#    most_recent = true
#  }
#}

source "amazon-ebs" "builder" {
  ami_name      = "${var.image_name}-{{timestamp}}"
  instance_type = "${var.instance_type}"
  region        = "${var.region}"
  source_ami = "${var.base_image}"
#  source_ami_filter {
#    filters = {
#      name                = "${var.base_image}"
#      root-device-type    = "ebs"
#      virtualization-type = "hvm"
#    }
#    most_recent = true
#    owners      = ["self", "amazon"]
#  }
  ssh_username = "${var.build_user}"
  tags = {
    Name = "${var.image_name}"
  }
}
