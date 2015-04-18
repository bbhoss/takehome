resource "aws_eip" "bastion" {
    vpc = true
    instance = "${aws_instance.bastion.id}"

    # Setup the new ssh config file for the bastion from the template
    provisioner "local-exec" {
      command = "sed s/BASTION_HOST_IP/${aws_eip.bastion.public_ip}/ < ssh.config.template > ssh.config "
    }
}

resource "aws_instance" "bastion" {
  instance_type = "t2.micro"
  ami = "ami-96a818fe"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.main.id}"
  security_groups = ["${aws_security_group.default.id}"]
  associate_public_ip_address = true

  connection {
    user = "centos"
    key_file = "${var.key_path}"
  }

  provisioner "remote-exec" {
    inline = [
        "sudo yum -y install nc"
    ]
  }
}