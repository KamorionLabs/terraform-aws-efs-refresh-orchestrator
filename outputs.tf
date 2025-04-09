output "iam_role_step_function" {
  value = aws_iam_role.step_function.arn
}

output "state_machine_arn" {
  value = aws_sfn_state_machine.refresh_env.arn
}

output "state_machine_name" {
  value = aws_sfn_state_machine.refresh_env.name
}

# Ces outputs ont été supprimés car les ressources correspondantes sont maintenant gérées en dehors du module
output "step_function_json_files_local_path" {
  value = ""
}

output "step_function_json_files" {
  value = {}
}

output "step_function_dynamodb_arn" {
  value = aws_dynamodb_table.dynamodbTable.arn
}

output "step_function_sns_arn" {
  value = local.sns_topic_arn
}
