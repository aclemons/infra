resource "aws_iam_policy" "lambda_permissions_boundary" {
  name        = "${var.prefix}-lambda-permissions-boundary"
  description = "Limit mail Lambda execution roles to mail runtime resources."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = [
          "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.prefix}-imapfilter:*",
          "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.prefix}-processor:*",
          "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda-insights:*",
        ]
      },
      {
        Effect   = "Allow"
        Action   = "ssm:GetParameter"
        Resource = local.parameter_arns
      },
      {
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = "arn:aws:kms:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:key/*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.${data.aws_region.current.region}.amazonaws.com"
          }
          ArnEquals = {
            "kms:EncryptionContext:PARAMETER_ARN" = local.parameter_arns
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::${var.prefix}-caffe"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:DeleteObject",
        ]
        Resource = "arn:aws:s3:::${var.prefix}-caffe/*"
      }
    ]
  })
}

resource "aws_iam_policy" "smtp_permissions_boundary" {
  name        = "${var.prefix}-smtp-permissions-boundary"
  description = "Limit the existing mail SMTP user to sending email."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ses:SendRawEmail"
        Resource = "*"
      }
    ]
  })
}
