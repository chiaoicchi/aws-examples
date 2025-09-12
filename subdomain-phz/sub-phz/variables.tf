variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "aws_parent_phz_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "parent_domain" {
  type = string
}

variable "sub_domain" {
  type = string
}

variable "cross_account_role_arn" {
  type      = string
  sensitive = true
}
