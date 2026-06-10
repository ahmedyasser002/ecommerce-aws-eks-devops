data "aws_iam_policy_document" "irsa_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
    }
  }
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = var.oidc_issuer_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.thumbprint_list
}

resource "aws_iam_role" "service_account" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.irsa_assume_role.json
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  count      = length(var.policy_arns)
  role       = aws_iam_role.service_account.name
  policy_arn = var.policy_arns[count.index]
}
