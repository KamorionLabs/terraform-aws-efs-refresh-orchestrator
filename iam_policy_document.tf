# Purpose: This file is used to create IAM policy documents for the lambda role and step function role.

#data "aws_efs_file_system" "old_efs" {
#  count          = var.delete_old_efs ? 1 : 0
#  file_system_id = var.efs_id
#}

#data "aws_efs_mount_target" "old_efs" {
#  count          = var.delete_old_efs ? 1 : 0
#  file_system_id = var.efs_id
#}

#data "aws_ssm_parameter" "efs_id" {
#  count = var.store_efs_metadata_in_ssm ? 1 : 0
#  name  = var.efs_id_ssm_parameter_name
#}

#data "aws_ssm_parameter" "efs_sub_path" {
#  count = var.store_efs_metadata_in_ssm ? 1 : 0
#  name  = var.efs_sub_path_ssm_parameter_name
#}

data "aws_iam_policy_document" "step_function_parameter_store" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:PutParameter"
    ]
    resources = [
      "*"
      #     data.aws_ssm_parameter.efs_id[0].arn,
      #     data.aws_ssm_parameter.efs_sub_path[0].arn
    ]
  }
}

data "aws_iam_policy_document" "step_function_delete_old_efs" {
  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:DeleteFileSystem"
    ]
    resources = ["arn:aws:elasticfilesystem:${local.current_region}:${local.current_account_id}:file-system/*"]
    #condition {
    #  test     = "StringEquals"
    #  variable = "aws:RequestTag/Name"
    #  values   = [var.efs_name]
    #}
  }
  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:DeleteMountTarget"
    ]
    resources = [
      "*"
    ]
  }
}

#
# Step Function IAM Policy Document
#
data "aws_iam_policy_document" "assume_from_step_functions" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "step_function_role" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem"
    ]
    resources = [aws_dynamodb_table.dynamodbTable.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [local.sns_topic_arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "backup:ListRecoveryPointsByResource",
      "backup:StartRestoreJob",
      "backup:DescribeRestoreJob",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [local.aws_backup_arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
      "kms:CreateGrant"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:CreateMountTarget",
      "elasticfilesystem:DescribeMountTargets",
      "elasticfilesystem:ListTagsForResource",
      "elasticfilesystem:TagResource",
      "elasticfilesystem:CreateAccessPoint",
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DeleteAccessPoint",
      "elasticfilesystem:DescribeMountTargetSecurityGroups",
      "elasticfilesystem:ModifyMountTargetSecurityGroups",
      "elasticfilesystem:DescribeLifecycleConfiguration",
      "elasticfilesystem:PutLifecycleConfiguration",
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeSubnets",
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
      "lambda:InvokeAsync",
      "lambda:GetFunctionConfiguration",
      "lambda:UpdateFunctionConfiguration"
    ]
    resources = [for lambda in aws_lambda_function.functions : lambda.arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "states:StartExecution"
    ]
    resources = [aws_sfn_state_machine.refresh_env.arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "tag:TagResources",
      "elasticfilesystem:CreateTags"
    ]
    resources = ["*"]
  }
}

#
# Lambda IAM Policy Document
#
data "aws_iam_policy_document" "assume_from_lambda" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_role" {
  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeMountTargets",
      "elasticfilesystem:ListTagsForResource",
      "elasticfilesystem:TagResource"
    ]
    resources = ["*"]
  }
}