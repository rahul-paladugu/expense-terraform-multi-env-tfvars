locals {
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"
  sg_tags = merge({Name = "sg-${var.environment}-${local.common_name}"}, var.common_tags)
  common_name = "${var.environment}-${var.project}-${var.region}"
  r53_common_name = "${local.common_name}.${var.r53_record_name}"
  public_r53_record = "${var.project}.${var.environment}.${var.r53_record_name}"
}