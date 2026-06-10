variable "cluster_name" {
  type = string
}

variable "oidc_issuer_url" {
  type = string
}

variable "service_account_name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "role_name" {
  type = string
}

variable "policy_arns" {
  type    = list(string)
  default = []
}

variable "thumbprint_list" {
  type    = list(string)
  default = ["9e99a48a9960b14926bb7f3b02e22da0afd1a3a5"]
}
