resource "aws_iam_role" "mail_automation" {
  name        = var.role_name
  description = "Deploy mail code from GHA."

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
              "token.actions.githubusercontent.com:sub" = "repo:aclemons/mail:*"
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
  role = aws_iam_role.mail_automation.id

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
  role = aws_iam_role.mail_automation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:Get*",
          "s3:List*",
        ],
        Resource = "arn:aws:s3:::caffe-terraform"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ],
        Resource = "arn:aws:s3:::caffe-terraform/${var.prefix}/terraform.tfstate"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Describe*",
          "dynamodb:List*",
          "dynamodb:Get*",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
        ],
        Resource = "arn:aws:dynamodb:*:*:table/caffe-terraform"
      },
    ]
  })
}

resource "aws_iam_role_policy" "ecr_permissions" {
  name = "ecr-permissions"
  role = aws_iam_role.mail_automation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:CreateRepository",
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

resource "aws_iam_role_policy" "cloudwatch_permissions" {
  name = "cloudwatch-permissions"
  role = aws_iam_role.mail_automation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = "logs:DescribeLogGroups",
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
      },
      {
        Effect   = "Allow",
        Action   = "logs:*",
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.prefix}*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda_permissions" {
  name = "lambda-permissions"
  role = aws_iam_role.mail_automation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "lambda:*"
        Resource = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${var.prefix}*"
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:ListFunctions",
          "lambda:ListEventSourceMappings",
          "lambda:GetLayerVersion",
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ssm_permissions" {
  name = "ssm-permissions"
  role = aws_iam_role.mail_automation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:Get*",
          "ssm:Describe*",
          "ssm:ListTagsForResource",
        ],
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.prefix}/*",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:PutParameter",
          "ssm:AddTagsToResource",
          "ssm:RemoveTagsFromResource",
        ],
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.prefix}/*",
        ]
      }
    ]
  })
}
