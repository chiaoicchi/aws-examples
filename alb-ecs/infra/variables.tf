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

variable "parent_domain" {
  type = string
}

variable "sub_domain" {
  type = string
}

variable "parent_domain_cross_account_role_arn" {
  type = string
}

variable "http_cidr_block" {
  type    = string
  default = "0.0.0.0/0"
}

variable "https_cidr_block" {
  type    = string
  default = "0.0.0.0/0"
}

variable "app_port" {
  type    = number
  default = 80
}

variable "need_authenticate" {
  type    = string
  default = false
}

variable "default_users" {
  type = map(
    object({
      email    = string
      password = string
    })
  )
  default = {
    "user" = {
      email    = "user@example.com"
      password = "TempPassword1!"
    }
  }
}

variable "enable_execute_command" {
  type    = bool
  default = false
}

variable "delete_app_ecr" {
  type    = bool
  default = false
}

variable "delete_alb_logs_bucket" {
  type    = bool
  default = false
}

variable "use_nat_gateway" {
  type    = bool
  default = true
}
