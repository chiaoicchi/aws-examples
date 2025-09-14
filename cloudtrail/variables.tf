variable "prefix" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "delete_s3" {
  type = bool
  default = false
}
