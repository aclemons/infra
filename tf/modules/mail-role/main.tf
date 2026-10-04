locals {
  lambda_role_arns = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.prefix}-imapfilter-lambda-role",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.prefix}-processor-lambda-role",
  ]

  lambda_policy_arns = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.prefix}-lambda-ssm-policy",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.prefix}-processor-ssm-policy",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.prefix}-processor-lambda-s3-policy",
  ]

  lambda_function_arns = [
    "arn:aws:lambda:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:function:${var.prefix}-imapfilter",
    "arn:aws:lambda:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:function:${var.prefix}-processor",
  ]

  lambda_layer_arns = [
    "arn:aws:lambda:${data.aws_region.current.region}:580247275435:layer:LambdaInsightsExtension:*",
    "arn:aws:lambda:${data.aws_region.current.region}:580247275435:layer:LambdaInsightsExtension-Arm64:*",
    "arn:aws:lambda:${data.aws_region.current.region}:187925254637:layer:AWS-Parameters-and-Secrets-Lambda-Extension:*",
    "arn:aws:lambda:${data.aws_region.current.region}:187925254637:layer:AWS-Parameters-and-Secrets-Lambda-Extension-Arm64:*",
  ]

  event_rule_arns = [
    "arn:aws:events:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:rule/${var.prefix}-imapfilter-cron",
    "arn:aws:events:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:rule/${var.prefix}-processor-cron",
  ]

  parameter_arns = [
    "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.prefix}/imapfilter/accounts",
    "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.prefix}/processor/imap_host",
    "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.prefix}/processor/imap_user",
    "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.prefix}/processor/imap_pass",
  ]
}

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
            StringEquals = {
              "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com",
              "token.actions.githubusercontent.com:sub" = "repo:aclemons/mail:environment:aws"
            }
          }
        }
      ]
    )
  })
}

resource "aws_iam_role" "mail_ci" {
  name        = "${var.prefix}-ci"
  description = "Download AWS Lambda layers for mail CI."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com",
            "token.actions.githubusercontent.com:sub" = "repo:aclemons/mail:environment:test"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ci_layer_permissions" {
  name = "lambda-layer-downloads"
  role = aws_iam_role.mail_ci.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "lambda:GetLayerVersion"
        Resource = local.lambda_layer_arns
      }
    ]
  })
}

resource "aws_iam_policy" "iam_permissions" {
  name = "${var.role_name}-iam-permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LambdaRoles"
        Effect = "Allow"
        Action = [
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:ListRolePolicies",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:UpdateRole",
          "iam:UpdateRoleDescription",
        ]
        Resource = local.lambda_role_arns
      },
      {
        Sid    = "BoundedLambdaRoles"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:PutRolePermissionsBoundary",
        ]
        Resource = local.lambda_role_arns
        Condition = {
          ArnEquals = {
            "iam:PermissionsBoundary" = aws_iam_policy.lambda_permissions_boundary.arn
          }
        }
      },
      {
        Sid    = "LambdaRoleAttachments"
        Effect = "Allow"
        Action = [
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
        ]
        Resource = local.lambda_role_arns
        Condition = {
          ArnEquals = {
            "iam:PolicyARN" = concat(local.lambda_policy_arns, [
              "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
              "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy",
            ])
          }
        }
      },
      {
        Sid    = "LambdaPolicies"
        Effect = "Allow"
        Action = [
          "iam:CreatePolicy",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicy",
          "iam:DeletePolicyVersion",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyTags",
          "iam:ListPolicyVersions",
          "iam:SetDefaultPolicyVersion",
          "iam:TagPolicy",
          "iam:UntagPolicy",
        ]
        Resource = local.lambda_policy_arns
      },
      {
        Sid      = "PassLambdaRoles"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = local.lambda_role_arns
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "lambda.amazonaws.com"
          }
        }
      },
      {
        Sid    = "ExistingSmtpUser"
        Effect = "Allow"
        Action = [
          "iam:GetUser",
          "iam:GetUserPolicy",
          "iam:ListUserTags",
          "iam:PutUserPolicy",
          "iam:DeleteUserPolicy",
          "iam:TagUser",
          "iam:UntagUser",
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.prefix}-ses-smtp-user.20240715-205419"
      },
      {
        Sid      = "BoundedSmtpUser"
        Effect   = "Allow"
        Action   = "iam:PutUserPermissionsBoundary"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.prefix}-ses-smtp-user.20240715-205419"
        Condition = {
          ArnEquals = {
            "iam:PermissionsBoundary" = aws_iam_policy.smtp_permissions_boundary.arn
          }
        }
      },
      {
        Sid    = "ProtectRuntimeBoundaries"
        Effect = "Deny"
        Action = [
          "iam:DeleteRolePermissionsBoundary",
          "iam:DeleteUserPermissionsBoundary",
        ]
        Resource = concat(local.lambda_role_arns, [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.prefix}-ses-smtp-user.20240715-205419",
        ])
      },
      {
        Sid    = "ProtectBoundaryPolicies"
        Effect = "Deny"
        Action = "iam:*"
        Resource = [
          aws_iam_policy.lambda_permissions_boundary.arn,
          aws_iam_policy.smtp_permissions_boundary.arn,
        ]
      },
      {
        Sid    = "ProtectAutomationRoles"
        Effect = "Deny"
        Action = "iam:*"
        Resource = [
          aws_iam_role.mail_automation.arn,
          aws_iam_role.mail_ci.arn,
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

resource "aws_iam_role_policy_attachment" "iam_permissions" {
  role       = aws_iam_role.mail_automation.name
  policy_arn = aws_iam_policy.iam_permissions.arn
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
          "s3:GetBucketLocation",
          "s3:ListBucket",
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
        Resource = [
          "arn:aws:s3:::caffe-terraform/${var.prefix}/terraform.tfstate",
          "arn:aws:s3:::caffe-terraform/${var.prefix}/terraform.tfstate.tflock",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy" "s3_permissions" {
  name = "s3-permissions"
  role = aws_iam_role.mail_automation.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:DeleteBucketPolicy",
          "s3:GetAccelerateConfiguration",
          "s3:GetBucket*",
          "s3:GetEncryptionConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
          "s3:PutBucketNotification",
          "s3:PutBucketPolicy",
          "s3:PutBucketPublicAccessBlock",
          "s3:PutBucketTagging",
          "s3:PutEncryptionConfiguration",
        ]
        Resource = "arn:aws:s3:::${var.prefix}-caffe"
      },
      {
        Effect = "Deny"
        Action = "s3:DeleteObject"
        NotResource = [
          "arn:aws:s3:::caffe-terraform/${var.prefix}/terraform.tfstate",
          "arn:aws:s3:::caffe-terraform/${var.prefix}/terraform.tfstate.tflock",
        ]
      }
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
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:CreateRepository",
          "ecr:DeleteLifecyclePolicy",
          "ecr:DeleteRepository",
          "ecr:DeleteRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetLifecyclePolicy",
          "ecr:GetRepositoryPolicy",
          "ecr:InitiateLayerUpload",
          "ecr:ListTagsForResource",
          "ecr:PutImage",
          "ecr:PutLifecyclePolicy",
          "ecr:SetRepositoryPolicy",
          "ecr:TagResource",
          "ecr:UntagResource",
          "ecr:UploadLayerPart",
        ]
        Resource = [
          "arn:aws:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository/${var.prefix}/imapfilter",
          "arn:aws:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository/${var.prefix}/processor",
        ]
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
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:DeleteRetentionPolicy",
          "logs:ListTagsForResource",
          "logs:PutRetentionPolicy",
          "logs:TagResource",
          "logs:UntagResource",
        ],
        Resource = [
          "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.prefix}-imapfilter",
          "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.prefix}-imapfilter:*",
          "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.prefix}-processor",
          "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.prefix}-processor:*",
        ]
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
        Effect = "Allow"
        Action = [
          "lambda:AddPermission",
          "lambda:CreateFunction",
          "lambda:DeleteFunction",
          "lambda:DeleteFunctionConcurrency",
          "lambda:GetFunction",
          "lambda:GetFunctionConcurrency",
          "lambda:GetFunctionConfiguration",
          "lambda:GetPolicy",
          "lambda:ListTags",
          "lambda:ListVersionsByFunction",
          "lambda:PutFunctionConcurrency",
          "lambda:RemovePermission",
          "lambda:TagResource",
          "lambda:UntagResource",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
        ]
        Resource = local.lambda_function_arns
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:GetLayerVersion",
        ],
        Resource = local.lambda_layer_arns
      }
    ]
  })
}

resource "aws_iam_role_policy" "ses_permissions" {
  name = "ses-permissions"
  role = aws_iam_role.mail_automation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:DeleteIdentity",
          "ses:GetIdentityDkimAttributes",
          "ses:GetIdentityMailFromDomainAttributes",
          "ses:GetIdentityVerificationAttributes",
          "ses:SetIdentityMailFromDomain",
          "ses:VerifyDomainDkim",
          "ses:VerifyDomainIdentity",
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
          "ssm:DescribeParameters",
        ],
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:ListTagsForResource",
          "ssm:PutParameter",
          "ssm:AddTagsToResource",
          "ssm:RemoveTagsFromResource",
        ],
        Resource = local.parameter_arns
      }
    ]
  })
}

resource "aws_iam_role_policy" "events" {
  name = "events-permissions"
  role = aws_iam_role.mail_automation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "events:DeleteRule",
          "events:DescribeRule",
          "events:ListTagsForResource",
          "events:ListTargetsByRule",
          "events:PutRule",
          "events:RemoveTargets",
          "events:TagResource",
          "events:UntagResource",
        ]
        Resource = local.event_rule_arns
      },
      {
        Effect   = "Allow"
        Action   = "events:PutTargets"
        Resource = local.event_rule_arns
        Condition = {
          "ForAllValues:ArnEquals" = {
            "events:TargetArn" = local.lambda_function_arns
          }
          Null = {
            "events:TargetArn" = "false"
          }
        }
      }
    ]
  })
}
