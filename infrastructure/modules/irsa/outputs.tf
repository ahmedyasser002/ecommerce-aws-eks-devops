output "service_account_role_arn" {
  value = aws_iam_role.service_account.arn
}

output "service_account_role_name" {
  value = aws_iam_role.service_account.name
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.eks.arn
}
