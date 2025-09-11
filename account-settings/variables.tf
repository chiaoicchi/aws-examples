variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "admin_users" {
  type = map(
    object({
      given_name   = string
      family_name  = string
      display_name = string
      email        = string
    })
  )
}

