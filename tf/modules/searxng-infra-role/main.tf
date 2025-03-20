resource "aws_iam_role" "searxng_infra_automation" {
  name        = var.role_name
  description = "Deploy searxng infra code from GHA."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect = "Allow",
          Action = "sts:AssumeRoleWithWebIdentity",
          Principal = {
            Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
          },
          Condition = {
            StringLike = {
              "token.actions.githubusercontent.com:sub" = "repo:aclemons/searxng-infra:*"
            }
            StringEquals = {
              "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            }
          }
        }
      ]
    )
  })
}

resource "aws_iam_role_policy" "iam_permissions" {
  name = "iam-permissions"
  role = aws_iam_role.searxng_infra_automation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadPerms"
        Effect = "Allow"
        Action = [
          "iam:Get*"
        ],
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.prefix}*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.prefix}*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.prefix}*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.prefix}*",
        ]
      },
      {
        Sid    = "ListAllPerms"
        Effect = "Allow"
        Action = [
          "iam:List*",
        ],
        Resource = [
          "*",
        ]
      },
      {
        Sid    = "AlterPerms"
        Effect = "Allow"
        Action = [
          "iam:Add*",
          "iam:Create*",
          "iam:Update*",
          "iam:Put*",
          "iam:Attach*",
          "iam:Detach*",
          "iam:Delete*",
          "iam:Remove*",
          "iam:PassRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:TagPolicy",
          "iam:UntagPolicy",
          "iam:GenerateServiceLastAccessedDetails",
          "iam:GenerateCredentialReport",
          "iam:TagInstanceProfile",
          "iam:UntagInstanceProfile",
        ],
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.prefix}*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.prefix}*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.prefix}*",
        ]
      },
      {
        Sid    = "DenyPerms"
        Effect = "Deny"
        Action = [
          "iam:CreateUser",
          "iam:DeleteUser",
        ],
        Resource = [
          "*",
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "terraform_permissions" {
  name = "terraform-permissions"
  role = aws_iam_role.searxng_infra_automation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:Get*",
          "s3:Put*",
          "s3:List*",
          "s3:CreateBucket"
        ],
        Resource = "arn:aws:s3:::${var.prefix}-*terraform"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ],
        Resource = "arn:aws:s3:::${var.prefix}-*terraform/*/terraform.tfstate"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Describe*",
          "dynamodb:List*",
          "dynamodb:Get*",
          "dynamodb:CreateTable",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:TagResource",
          "dynamodb:UntagResource",
        ],
        Resource = "arn:aws:dynamodb:*:*:table/${var.prefix}-*terraform"
      },
    ]
  })
}

resource "aws_iam_role_policy" "ecr_permissions" {
  name = "ecr-permissions"
  role = aws_iam_role.searxng_infra_automation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "ecr:*"
        Resource = "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/${var.prefix}*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_permissions" {
  name = "lambda-permissions"
  role = aws_iam_role.searxng_infra_automation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:GetFunctionConfiguration",
          "lambda:GetFunctionUrlConfig",
          "lambda:PublishVersion",
          "lambda:UpdateFunctionCode",
        ],
        Resource = [
          "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${var.prefix}-*",
        ],
      }
    ]
  })
}
