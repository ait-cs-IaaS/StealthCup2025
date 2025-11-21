source "amazon-ebs" "builder" {
  ami_name      = "${var.image_name}-{{timestamp}}"
  instance_type = "${var.instance_type}"
  region        = "${var.region}"
  source_ami = "${var.base_image}"

  ssh_username = "${var.build_user}"
  tags = {
    Name = "${var.image_name}"
  }
}
