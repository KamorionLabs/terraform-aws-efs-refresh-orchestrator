# Version générique du fichier main.tf
# Ce fichier remplace main.tf

# Dans la version générique, nous n'avons plus besoin de générer les fichiers d'input JSON
# car ils seront fournis par le module racine (05_refresh_env)

locals {
  step_function_definition_file = var.use_jsonata_template ? "step_function_definition_jsonata.json" : "step_function_definition.json"
}

# Une seule step function générique
resource "aws_sfn_state_machine" "refresh_env" {
  name       = local.name_cc
  role_arn   = aws_iam_role.step_function.arn
  definition = templatefile("${path.module}/templates/${local.step_function_definition_file}", {})
}

# Bucket S3 (optionnel)
resource "aws_s3_bucket" "refresh_bucket" {
  count         = var.create_s3_bucket ? 1 : 0
  bucket        = var.s3_bucket_name == null ? null : var.s3_bucket_name
  bucket_prefix = var.s3_bucket_name == null ? local.name : null
}

# Suppression des ressources de génération des fichiers d'input JSON
# local_file.step_function_json_input
# aws_s3_object.step_function_json_input
# aws_s3_object.step_function_json_input_hash
