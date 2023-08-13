resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"]
}

module "koinobori_role" {
  source = "../modules/koinobori-role"

  prefix    = "koinobori"
  role_name = "koinobori-automation"
}

module "mail_role" {
  source = "../modules/mail-role"

  prefix    = "mail"
  role_name = "mail-automation"
}
