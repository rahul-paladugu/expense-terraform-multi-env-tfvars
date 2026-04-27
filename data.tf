#Query AMI-ID
data "aws_ami" "expense_ami" {
  most_recent      = true
  owners           = ["973714476881"]

  filter {
    name   = "name"
    values = ["Redhat-9-DevOps-Practice"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
#Query R53-ZONE-ID
data "aws_route53_zone" "expense_r53" {
  name         = "rscloudservices.icu"
  private_zone = false
}