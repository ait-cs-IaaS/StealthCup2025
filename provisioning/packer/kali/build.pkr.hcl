build {
  sources = ["source.amazon-ebs.builder"]

  provisioner "shell" {
    inline = [
      "echo 'Waiting for network and system services to stabilize...'",
      "until ping -c1 google.com >/dev/null 2>&1; do sleep 5; done",
      "echo 'System is ready!'"
    ]
  }

  provisioner "ansible" {
    groups        = "${var.ansible_groups}"
    playbook_file = "playbook/main.yml"
    user          = "${var.build_user}"
    use_proxy     = false
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Vars }} {{ .Path }}"
    script          = "scripts/cleanup.sh"
  }
}
