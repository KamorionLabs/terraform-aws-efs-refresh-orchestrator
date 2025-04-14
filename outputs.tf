output "iam_role_step_function" {
  value = aws_iam_role.step_function.arn
}

output "state_machine_arn" {
  value = aws_sfn_state_machine.refresh_env.arn
}

output "state_machine_name" {
  value = aws_sfn_state_machine.refresh_env.name
}

output "step_function_dynamodb_arn" {
  value = aws_dynamodb_table.dynamodbTable.arn
}

output "step_function_sns_arn" {
  value = local.sns_topic_arn
}

output "lambdas" {
  value = { for k, v in aws_lambda_function.functions : k => {
    name = v.function_name
    arn  = v.arn
    }
  }
}

output "lambda_security_group_id" {
  value = aws_security_group.lambda.id
}
