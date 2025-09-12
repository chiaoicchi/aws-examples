variable "aws_region" {
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

variable "sub_phz_account_id" {
  type = string
}
