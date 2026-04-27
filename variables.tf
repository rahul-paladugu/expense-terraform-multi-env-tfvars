variable "components" {
    default = ["mysql", "backend", "frontend"]
}
variable "region" {
    default = "use1"
}
variable "environment" {
    type = string
}
variable "project" {
    default = "expense"
}
variable "common_tags" {
    default = {
        Terraform = "true"
        Project = "expense"
    }
}

variable "sg_ports" {
    default = ["22","80","3306"]
}

variable "r53_record_name" {
    default = "rscloudservices.icu"
}