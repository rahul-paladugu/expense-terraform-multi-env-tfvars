#Create instance required for the project by capturing ami-id dynamically using data query.
resource "aws_instance" "expense_instances" {
  count         = length(var.components)
  ami           = data.aws_ami.expense_ami.id
  vpc_security_group_ids = [aws_security_group.expense_sg.id]
  instance_type = local.instance_type
  tags          = merge({Name = "${var.components[count.index]}-${local.common_name}"}, var.common_tags)
  provisioner "local-exec" {
  command = "echo The server's IP address is ${self.private_ip}"
  on_failure = continue
  }
  provisioner "local-exec" {
  command = "echo Destroyed the environment"
  on_failure = continue
  when = destroy
  }
}
#Create a security group for the project update the ports using Dynamic Block
resource "aws_security_group" "expense_sg" {
  name        = "allow-limited-access"
  description = "Allow expense inbound and outbound traffic"
  dynamic "egress" {
  for_each = var.sg_ports
  content {
    from_port        = egress.value
    to_port          = egress.value
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  }
  dynamic "ingress" {
  for_each = var.sg_ports
  content {
    from_port        = ingress.value
    to_port          = ingress.value
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  }
  tags = local.sg_tags
}

#Create R53 records for the instances
resource "aws_route53_record" "expense_r53_records" {
  count = length(var.components)
  zone_id = data.aws_route53_zone.expense_r53.zone_id
  name    = "${var.components[count.index]}-${local.r53_common_name}"
  type    = "A"
  ttl     = 10
  allow_overwrite = true
  records = [aws_instance.expense_instances[count.index].private_ip]
}

#Create R53 records for the fronted server-public access
resource "aws_route53_record" "expense_r53_record_Public" {
  count = contains(var.components, "frontend") ? 1 : 0
  zone_id = data.aws_route53_zone.expense_r53.zone_id
  name    = local.public_r53_record
  type    = "A"
  ttl     = 10
  allow_overwrite = true
  records = [aws_instance.expense_instances[index(var.components, "frontend")].public_ip]
}