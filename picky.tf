resource "aws_eip" "debug_pub" {
    vpc = true
    instance = "${aws_instance.picky.id}"
}

resource "aws_elb" "main-picky-elb" {
  vpc_id = "${aws_vpc.main.id}"
  depends_on = ["aws_internet_gateway.gw"]
  name = "main-picky-elb"
  subnets = ["${aws_subnet.main.id}"]
  security_groups = ["${aws_security_group.default.id}"]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  instances = ["${aws_instance.picky.*.id}"]
}


resource "aws_instance" "picky" {
  connection {
    user = "centos"
    key_file = "${var.key_path}"
  }

  instance_type = "t2.micro"
  ami = "ami-96a818fe"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.main.id}"
  security_groups = ["${aws_security_group.default.id}"]
  count = 2
  associate_public_ip_address = true

  provisioner "remote-exec" {
    inline = [
        "sudo yum -y install epel-release",
        "sudo yum -y install nginx",
        "sudo systemctl start nginx.service"
    ]
  }
}
