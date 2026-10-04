resource "aws_iam_role" "koinobori_automation" {
  name        = var.role_name
  description = "Deploy koinobori code from GHA."

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
            StringEquals = {
              "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com",
              "token.actions.githubusercontent.com:sub" = "repo:aclemons/koinobori:environment:dev"
            }
          }
        }
      ]
    )
  })
}

resource "aws_iam_role_policy" "ecr_permissions" {
  name = "ecr-permissions"
  role = aws_iam_role.koinobori_automation.id

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
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
        ]
        Resource = "arn:aws:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository/${var.prefix}/dev"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_permissions" {
  name = "lambda-permissions"
  role = aws_iam_role.koinobori_automation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:GetFunctionConfiguration",
          "lambda:UpdateFunctionCode",
        ],
        Resource = [
          "arn:aws:lambda:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:function:${var.prefix}-dev-api",
          "arn:aws:lambda:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:function:${var.prefix}-dev-migrations",
        ],
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:GetFunctionUrlConfig",
        ],
        Resource = [
          "arn:aws:lambda:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:function:${var.prefix}-dev-api",
        ],
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
        ],
        Resource = [
          "arn:aws:lambda:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:function:${var.prefix}-dev-migrations",
        ],
      },
    ]
  })
}
