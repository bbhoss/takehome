output "address" {
  value = "${aws_elb.main-picky-elb.dns_name}"
}
output "bastion-address" {
  value = "${aws_eip.bastion.public_ip}"
}
