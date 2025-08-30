# Sources

source "amazon-ebs" "builder" {
  ami_name      = "${var.image_name}-{{timestamp}}"
  instance_type = "${var.instance_type}"
  region        = "${var.region}"
  source_ami = "${var.base_image}"

  ssh_username = "${var.build_user}"
  tags = {
    Name = "${var.image_name}"
  }

  launch_block_device_mappings {
    device_name         = "/dev/sda1"
    volume_size           = 40           # Set volume size in GB
    volume_type           = "gp3"        # General Purpose SSD
    delete_on_termination = true
  }
}