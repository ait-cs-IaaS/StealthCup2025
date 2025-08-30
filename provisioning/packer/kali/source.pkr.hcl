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

  # Set Root Volume Size (in GiB)
  launch_block_device_mappings {
      device_name = "/dev/xvda"  # Default root volume for AWS
      volume_size = 25           # Set root volume size (e.g., 50 GiB)
      volume_type = "gp3"        # Use general-purpose SSD
      delete_on_termination = true
  }
}
