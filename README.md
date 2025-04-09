# Terraform Module 

This is a Terraform module for deploying the EFS refresh orchestrator on AWS.

## How to Use This Module

Basic Example :

## Running the EFS Refresh Step Function

This module includes a shell script `run_efs_refresh.sh` that can be used to launch the Step Function with a JSON input file. The script handles retrieving the Step Function ARN and launching the execution.

### Script Usage

```bash
./run_efs_refresh.sh --name RefreshEnvEfsKamorionPreprod --input efs_refresh_input.json
```

Options:
- `-n, --name NAME`: Name of the Step Function (required)
- `-i, --input FILE`: JSON input file (required)
- `-p, --profile PROFILE`: AWS profile to use (optional)
- `-r, --region REGION`: AWS region (optional, default: eu-west-3)
- `-h, --help`: Display help information

### Step Function Input Parameters

The Step Function requires a JSON input file with the following parameters:

| Parameter | Description | Required |
|-----------|-------------|:--------:|
| `SourceEFSName` | Name of the source EFS file system (usually in prod) | Yes |
| `EFSName` | Name of the target EFS file system (usually in preprod) | Yes |
| `AWSBackupRoleArn` | ARN of the IAM role for AWS Backup | Yes |
| `Encrypted` | Boolean indicating whether the file system should be encrypted | Yes |
| `KmsKeyId` | ID of the KMS key for encryption | No |
| `newFileSystem` | Boolean indicating whether to create a new file system | Yes |
| `DeleteOldEfs` | Boolean indicating whether to delete the old file system | No (default: false) |
| `EFSLifecyclePolicies` | Lifecycle policies for the file system | Yes |
| `LambdaEfsFunction` | Name of the Lambda function for EFS operations | Yes |
| `StoreEfsMetadataInSSM` | Boolean indicating whether to store EFS metadata in SSM | No (default: false) |
| `EfsIdSSMParameterName` | Name of the SSM parameter for the EFS ID | No |
| `EfsSubPathSSMParameterName` | Name of the SSM parameter for the EFS sub-path | No |
| `SecurityGroupID` | List of security group IDs | Yes |
| `SubnetIDs` | List of subnet IDs | Yes |
| `DynamoDBTableName` | Name of the DynamoDB table to store refresh state | Yes |
| `SNSTopicArn` | ARN of the SNS topic for notifications | Yes |
| `SNSSubject` | Subject of the SNS message in case of success | Yes |
| `SNSMessage` | Body of the SNS message in case of success | Yes |
| `SNSSubjectFailure` | Subject of the SNS message in case of failure | Yes |
| `SNSMessageFailure` | Body of the SNS message in case of failure | Yes |
| `TagApplication` | Value of the Application tag | Yes |
| `TagEnvironment` | Value of the Environment tag | Yes |
| `Tags` | Map of tags to apply to resources | Yes |
| `ItemsToRestore` | List of items to restore | No |

### Example JSON Input File

```json
{
  "SourceEFSName": "kamorion-prod",
  "EFSName": "kamorion-preprod",
  "AWSBackupRoleArn": "arn:aws:iam::910712879551:role/service-role/AWSBackupDefaultServiceRole",
  "Encrypted": true,
  "KmsKeyId": "alias/aws/elasticfilesystem",
  "newFileSystem": true,
  "DeleteOldEfs": true,
  "EFSLifecyclePolicies": [
    {
      "TransitionToIA": "AFTER_30_DAYS"
    }
  ],
  "LambdaEfsFunction": "GetEfsRestoreBackupDirectory-kamorion-preprod",
  "StoreEfsMetadataInSSM": true,
  "EfsIdSSMParameterName": "/kamorion/preprod/efs/id",
  "EfsSubPathSSMParameterName": "/kamorion/preprod/efs/path",
  "SecurityGroupID": ["sg-0123456789abcdef0"],
  "SubnetIDs": [
    "subnet-0381a28930b779eb0",
    "subnet-06599c4ebc1490f87",
    "subnet-0a609a34c9101b305"
  ],
  "DynamoDBTableName": "RefreshEnvEfsKamorionPreprod",
  "SNSTopicArn": "arn:aws:sns:eu-west-3:910712879551:RefreshEnvEfsKamorionPreprod",
  "SNSSubject": "EFS refresh completed successfully",
  "SNSMessage": "The refresh of the kamorion-preprod EFS file system has been completed successfully.",
  "SNSSubjectFailure": "EFS refresh failed",
  "SNSMessageFailure": "The refresh of the kamorion-preprod EFS file system has failed. Please check the logs for more information.",
  "TagApplication": "kamorion",
  "TagEnvironment": "preprod",
  "Tags": {
    "Application": "kamorion",
    "Environment": "preprod"
  }
}
```

```hcl
module "refresh_efs" {
  source = "akirosit/efs-refresh-orchestrator/aws"

  # Network informations
  vpc_id              = "vpc-XXX"
  private_subnets_ids = [ "subnet-xxx", "subnet-yyy"] # used for lambda deployment

  # Main informations
  source_efs_id    = "fs-xxxx"
  efs_id           = "fs-yyyy"
  efs_sg_id        = "sg-xxxx"
  encrypted        = false
  kms_key_id       = null
  items_to_restore = [ "/path" ]
  delete_old_efs   = false

  # Store EFS infos in SSM Parameter store
  store_efs_metadata_in_ssm       = true
  efs_id_ssm_parameter_name       = "/efs-1/efs-id"
  efs_sub_path_ssm_parameter_name = "/efs-1/efs-sub-path"

  # For refresh inputs
  s3_bucket_name                           = "bucket-refresh-xxx"
  put_step_function_input_json_files_on_s3 = true

  # Tags
  app_name = "refresh"
  env_name = "preprod"
  tags = {
    Name            = "efs-1"
    CostCenter      = "CCXXYYY"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.0.0 |
| <a name="provider_local"></a> [local](#provider\_local) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | Application name | `string` | n/a | yes |
| <a name="input_create_s3_bucket"></a> [create\_s3\_bucket](#input\_create\_s3\_bucket) | Create S3 bucket to put step function input json files | `bool` | `false` | no |
| <a name="input_delete_old_efs"></a> [delete\_old\_efs](#input\_delete\_old\_efs) | Delete old EFS | `bool` | `false` | no |
| <a name="input_efs_id"></a> [efs\_id](#input\_efs\_id) | The EFS id to be refreshed | `string` | n/a | yes |
| <a name="input_efs_id_ssm_parameter_name"></a> [efs\_id\_ssm\_parameter\_name](#input\_efs\_id\_ssm\_parameter\_name) | SSM parameter name to store the EFS ID | `string` | n/a | yes |
| <a name="input_efs_sg_id"></a> [efs\_sg\_id](#input\_efs\_sg\_id) | The EFS security group ID | `string` | n/a | yes |
| <a name="input_efs_sub_path_ssm_parameter_name"></a> [efs\_sub\_path\_ssm\_parameter\_name](#input\_efs\_sub\_path\_ssm\_parameter\_name) | SSM parameter name to store the EFS sub path | `string` | n/a | yes |
| <a name="input_encrypted"></a> [encrypted](#input\_encrypted) | New/refresh cluster is encrypted | `bool` | `false` | no |
| <a name="input_env_name"></a> [env\_name](#input\_env\_name) | Environment name | `string` | n/a | yes |
| <a name="input_items_to_restore"></a> [items\_to\_restore](#input\_items\_to\_restore) | Items to restore from source EFS | `list(string)` | n/a | yes |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | KMS key to encrypt new/refresh cluster | `string` | `null` | no |
| <a name="input_private_subnets_ids"></a> [private\_subnets\_ids](#input\_private\_subnets\_ids) | The private subnets IDs (where lambda functions will be deployed) | `list(string)` | n/a | yes |
| <a name="input_put_step_function_input_json_files_on_s3"></a> [put\_step\_function\_input\_json\_files\_on\_s3](#input\_put\_step\_function\_input\_json\_files\_on\_s3) | Push or not step function input json files to S3 bucket | `bool` | `false` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | Name of the bucket s3 created within this module or existing S3 name to put step function input json files | `string` | `null` | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | Existing SNS topic ARN to send notifications | `string` | `null` | no |
| <a name="input_source_efs_id"></a> [source\_efs\_id](#input\_source\_efs\_id) | The source EFS ID | `string` | n/a | yes |
| <a name="input_store_efs_metadata_in_ssm"></a> [store\_efs\_metadata\_in\_ssm](#input\_store\_efs\_metadata\_in\_ssm) | Store EFS ID and sub path in SSM | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `map('BusinessUnit`,`XYZ`) | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC ID (where lambda functions will be deployed) | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam_role_step_function"></a> [iam\_role\_step\_function](#output\_iam\_role\_step\_function) | n/a |
| <a name="output_state_machine_name"></a> [state\_machine\_name](#output\_state\_machine\_name) | n/a |
| <a name="output_step_function_dynamodb_arn"></a> [step\_function\_dynamodb\_arn](#output\_step\_function\_dynamodb\_arn) | n/a |
| <a name="output_step_function_json_files"></a> [step\_function\_json\_files](#output\_step\_function\_json\_files) | n/a |
| <a name="output_step_function_sns_arn"></a> [step\_function\_sns\_arn](#output\_step\_function\_sns\_arn) | n/a |
| <a name="output_vpc_security_group_for_lambda"></a> [vpc\_security\_group\_for\_lambda](#output\_vpc\_security\_group\_for\_lambda) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table.dynamodbTable](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_iam_policy.lambda_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.step_function_delete_old_efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.step_function_parameter_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.step_function_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.step_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.lambda_basic_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_vpc_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.step_function_delete_old_efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.step_function_parameter_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.step_function_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.functions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_layer_version.layer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_layer_version) | resource |
| [aws_s3_bucket.refresh_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_object.lambda_functions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.lambda_functions_hash](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.step_function_json_input](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_s3_object.step_function_json_input_hash](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_security_group.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.efs_from_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.lambda_efs_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.lambda_https_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_sfn_state_machine.refresh_env](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sfn_state_machine) | resource |
| [aws_sns_topic.refresh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [local_file.step_function_json_input](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.pip_install](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [archive_file.lambda_functions](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.lambda_layers](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_efs_file_system.old_efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/efs_file_system) | data source |
| [aws_iam_policy_document.assume_from_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.assume_from_step_functions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.step_function_delete_old_efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.step_function_parameter_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.step_function_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
