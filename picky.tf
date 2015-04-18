resource "aws_elb" "main-picky-elb" {
  vpc_id = "${aws_vpc.main.id}"
  depends_on = ["aws_internet_gateway.gw"]
  name = "main-picky-elb"
  subnets = ["${aws_subnet.main.id}"]
  security_groups = ["${aws_security_group.default.id}"]

  listener {
    instance_port = 8000
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:8000/books?query=the"
    interval = 10
  }

  instances = ["${aws_instance.picky.*.id}"]
}


resource "aws_instance" "picky" {
  instance_type = "t2.medium"
  ami = "ami-96a818fe"
  key_name = "${var.key_name}"
  subnet_id = "${aws_subnet.main.id}"
  security_groups = ["${aws_security_group.default.id}"]
  count = 2
  associate_public_ip_address = true
}
