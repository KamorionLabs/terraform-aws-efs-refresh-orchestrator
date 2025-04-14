# AWS EFS Refresh Orchestrator

This Terraform module deploys a comprehensive solution for refreshing Amazon EFS file systems from one environment to another (typically from production to non-production environments). It automates the entire refresh process, including backup restoration, file system creation, and mount target configuration.

## Introduction

The EFS Refresh Orchestrator provides a fully automated way to create copies of your production EFS file systems in non-production environments. This is particularly useful for:

- Creating realistic test environments with production-like data
- Troubleshooting issues that only occur in production
- Testing file system changes before applying them to production
- Validating application changes against production-like data

The orchestrator uses AWS Step Functions to coordinate the refresh process, ensuring reliable execution and proper error handling.

## Features

### Supported File Systems

- **Amazon EFS**: Full support for Amazon Elastic File System
- **Other file systems**: Not currently supported

### Refresh Methods

- **AWS Backup-based refresh**: Restores an EFS file system from AWS Backup
- **Selective restore**: Restore specific directories or files from the source EFS

### File System Management

- **New file system creation**: Create a new EFS file system during the refresh
- **Existing file system replacement**: Replace an existing EFS file system with a refreshed copy
- **Mount target configuration**: Automatically configure mount targets in specified subnets
- **Lifecycle policies**: Apply lifecycle policies to the refreshed file system
- **Old file system deletion**: Optionally delete the old file system after refresh

### Integration Capabilities

- **S3 integration**: Store configuration in S3
- **SSM Parameter Store**: Store EFS metadata in SSM Parameter Store
- **SNS notifications**: Receive notifications about refresh status
- **DynamoDB tracking**: Track refresh history and status

### Advanced Features

- **Encryption**: Support for encrypted file systems
- **KMS integration**: Use custom KMS keys for encryption
- **Security group management**: Configure security groups for mount targets
- **Lambda integration**: Use Lambda functions for EFS operations

## Prerequisites

### General Requirements

- **AWS Account**: You need an AWS account with appropriate permissions
- **Terraform**: Version 1.1.0 or later
- **AWS Provider**: Version 3.0.0 or later
- **VPC with private subnets**: For Lambda function deployment and EFS mount targets
- **S3 bucket**: For storing configuration (can be created by the module)

### AWS Backup Requirements

- **AWS Backup vault**: With backups of the source EFS file system
- **IAM role for AWS Backup**: Role with permissions to restore EFS file systems

### Security Requirements

- **KMS keys**: For encrypting file systems (optional)
- **Security groups**: For controlling access to EFS mount targets
- **IAM roles**: With appropriate permissions for Step Functions and Lambda

## Usage

The EFS Refresh Orchestrator module is deployed using Terraform, but the actual refresh operation is controlled through a JSON input file that is passed to the Step Function. This approach provides maximum flexibility and allows for detailed configuration of the refresh process.

### Module Deployment

First, deploy the module using Terraform:

```hcl
module "efs_refresh_orchestrator" {
  source = "KamorionLabs/efs-refresh-orchestrator/aws"

  # Basic infrastructure settings
  vpc_id              = "vpc-12345678"
  private_subnets_ids = ["subnet-12345678", "subnet-87654321"]
  
  # S3 bucket for storing input files (optional)
  create_s3_bucket = true
  s3_bucket_name   = "my-efs-refresh-bucket"
  
  # Basic tagging
  app_name = "myapp"
  env_name = "preprod"
  tags = {
    Environment = "preprod"
    CostCenter  = "12345"
  }
}
```

### Step Function Execution

After deploying the module, you execute the refresh process by running the Step Function with a JSON input file. The JSON file contains all the specific configuration for the refresh operation, including source and target EFS details, encryption settings, items to restore, etc.

You can run the Step Function using the provided shell script:

```bash
./run_efs_refresh.sh --name RefreshEnvEfsMyAppPreprod --input efs_refresh_input.json
```

Or directly through the AWS CLI:

```bash
aws stepfunctions start-execution \
  --state-machine-arn arn:aws:states:region:account-id:stateMachine:RefreshEnvEfsMyAppPreprod \
  --input file://efs_refresh_input.json
```

### Input JSON Examples

#### Basic Refresh

```json
{
  "SourceEFSName": "fs-12345678",
  "EFSName": "fs-87654321",
  "AWSBackupRoleArn": "arn:aws:iam::123456789012:role/AWSBackupRole",
  "Encrypted": true,
  "KmsKeyId": "alias/aws/elasticfilesystem",
  "newFileSystem": false,
  "DeleteOldEfs": false,
  "EFSLifecyclePolicies": [
    {
      "TransitionToIA": "AFTER_30_DAYS"
    }
  ],
  "LambdaEfsFunction": "GetEfsRestoreBackupDirectory",
  "SecurityGroupID": ["sg-0123456789abcdef0"],
  "SubnetIDs": [
    "subnet-0123456789abcdef0",
    "subnet-0123456789abcdef1"
  ],
  "ItemsToRestore": ["/data", "/config"],
  "DynamoDBTableName": "EfsRefreshTracking",
  "SNSTopicArn": "arn:aws:sns:region:123456789012:topic",
  "SNSSubject": "EFS refresh completed",
  "SNSMessage": "EFS refresh completed successfully",
  "SNSSubjectFailure": "EFS refresh failed",
  "SNSMessageFailure": "EFS refresh failed",
  "TagApplication": "myapp",
  "TagEnvironment": "preprod",
  "Tags": {
    "Application": "myapp",
    "Environment": "preprod"
  }
}
```

#### Creating a New File System

```json
{
  "SourceEFSName": "fs-12345678",
  "EFSName": "new-efs",
  "AWSBackupRoleArn": "arn:aws:iam::123456789012:role/AWSBackupRole",
  "Encrypted": true,
  "KmsKeyId": "alias/aws/elasticfilesystem",
  "newFileSystem": true,
  "DeleteOldEfs": false,
  "EFSLifecyclePolicies": [
    {
      "TransitionToIA": "AFTER_30_DAYS"
    },
    {
      "TransitionToArchive": "AFTER_90_DAYS"
    }
  ],
  "LambdaEfsFunction": "GetEfsRestoreBackupDirectory",
  "StoreEfsMetadataInSSM": true,
  "EfsIdSSMParameterName": "/myapp/preprod/efs-id",
  "EfsSubPathSSMParameterName": "/myapp/preprod/efs-path",
  "SecurityGroupID": ["sg-0123456789abcdef0"],
  "SubnetIDs": [
    "subnet-0123456789abcdef0",
    "subnet-0123456789abcdef1"
  ],
  "ItemsToRestore": ["/data", "/config", "/logs"],
  "DynamoDBTableName": "EfsRefreshTracking",
  "SNSTopicArn": "arn:aws:sns:region:123456789012:topic",
  "SNSSubject": "EFS refresh completed",
  "SNSMessage": "EFS refresh completed successfully",
  "SNSSubjectFailure": "EFS refresh failed",
  "SNSMessageFailure": "EFS refresh failed",
  "TagApplication": "myapp",
  "TagEnvironment": "preprod",
  "Tags": {
    "Application": "myapp",
    "Environment": "preprod",
    "CostCenter": "12345"
  }
}
```

## Step Function Input JSON Format

The EFS Refresh Orchestrator Step Function requires a JSON input file that defines all aspects of the refresh operation. This section explains the structure and format of this JSON file in detail.

### JSON Structure Overview

The input JSON is organized into several logical sections:

1. **File System Identifiers**: Defines the source and target EFS file systems
2. **File System Configuration**: Specifies encryption, lifecycle policies, and other settings
3. **Restoration Configuration**: Controls what and how to restore from the source EFS
4. **Mount Target Configuration**: Configures network settings for the EFS mount targets
5. **Metadata Storage**: Controls storing EFS metadata in SSM Parameter Store
6. **Notification and Tracking**: Configures SNS notifications and DynamoDB tracking
7. **Tagging**: Defines tags to apply to AWS resources

### Core Parameters

These parameters are required for basic functionality:

```json
{
  "SourceEFSName": "prod-efs",                          // Source EFS to copy from
  "EFSName": "preprod-efs",                             // Target EFS name
  "AWSBackupRoleArn": "arn:aws:iam::123456789012:role/AWSBackupRole", // IAM role for AWS Backup
  "Encrypted": true,                                    // Whether the EFS should be encrypted
  "newFileSystem": true,                                // Create a new file system
  "EFSLifecyclePolicies": [                             // Lifecycle policies for the EFS
    {
      "TransitionToIA": "AFTER_30_DAYS"
    }
  ],
  "LambdaEfsFunction": "GetEfsRestoreBackupDirectory",  // Lambda function for EFS operations
  "SecurityGroupID": ["sg-0123456789abcdef0"],          // Security groups for mount targets
  "SubnetIDs": [                                        // Subnets for mount targets
    "subnet-0123456789abcdef0",
    "subnet-0123456789abcdef1"
  ],
  "DynamoDBTableName": "EfsRefreshTracking",            // DynamoDB table for tracking
  "SNSTopicArn": "arn:aws:sns:region:123456789012:topic", // SNS topic for notifications
  "SNSSubject": "EFS refresh completed",                // Success notification subject
  "SNSMessage": "EFS refresh completed successfully",   // Success notification message
  "SNSSubjectFailure": "EFS refresh failed",            // Failure notification subject
  "SNSMessageFailure": "EFS refresh failed",            // Failure notification message
  "TagApplication": "myapp",                            // Application tag value
  "TagEnvironment": "preprod",                          // Environment tag value
  "Tags": {                                             // Tags for AWS resources
    "Application": "myapp",
    "Environment": "preprod"
  }
}
```

### Encryption Configuration

These parameters configure encryption for the EFS file system:

```json
{
  "Encrypted": true,                                    // Enable encryption
  "KmsKeyId": "alias/aws/elasticfilesystem"             // KMS key for encryption (optional)
}
```

### Restoration Configuration

These parameters control what to restore from the source EFS:

```json
{
  "ItemsToRestore": [                                   // Specific paths to restore
    "/data",
    "/config"
  ],
  "DeleteOldEfs": false                                 // Delete the old EFS after refresh
}
```

### SSM Parameter Store Integration

These parameters configure storing EFS metadata in SSM Parameter Store:

```json
{
  "StoreEfsMetadataInSSM": true,                        // Store EFS metadata in SSM
  "EfsIdSSMParameterName": "/myapp/preprod/efs-id",     // SSM parameter for EFS ID
  "EfsSubPathSSMParameterName": "/myapp/preprod/efs-path" // SSM parameter for EFS path
}
```

### Lifecycle Policies

These parameters configure lifecycle policies for the EFS file system:

```json
{
  "EFSLifecyclePolicies": [                             // Lifecycle policies for the EFS
    {
      "TransitionToIA": "AFTER_30_DAYS"                 // Move to Infrequent Access after 30 days
    },
    {
      "TransitionToArchive": "AFTER_90_DAYS"            // Move to Archive after 90 days
    }
  ]
}
```

### Complete Example

Here's a complete example that combines all the sections:

```json
{
  "SourceEFSName": "prod-efs",
  "EFSName": "preprod-efs",
  "AWSBackupRoleArn": "arn:aws:iam::123456789012:role/AWSBackupRole",
  "Encrypted": true,
  "KmsKeyId": "alias/aws/elasticfilesystem",
  "newFileSystem": true,
  "DeleteOldEfs": false,
  "EFSLifecyclePolicies": [
    {
      "TransitionToIA": "AFTER_30_DAYS"
    },
    {
      "TransitionToArchive": "AFTER_90_DAYS"
    }
  ],
  "LambdaEfsFunction": "GetEfsRestoreBackupDirectory",
  "StoreEfsMetadataInSSM": true,
  "EfsIdSSMParameterName": "/myapp/preprod/efs-id",
  "EfsSubPathSSMParameterName": "/myapp/preprod/efs-path",
  "SecurityGroupID": ["sg-0123456789abcdef0"],
  "SubnetIDs": [
    "subnet-0123456789abcdef0",
    "subnet-0123456789abcdef1",
    "subnet-0123456789abcdef2"
  ],
  "ItemsToRestore": [
    "/data",
    "/config",
    "/logs"
  ],
  "DynamoDBTableName": "EfsRefreshTracking",
  "SNSTopicArn": "arn:aws:sns:region:123456789012:topic",
  "SNSSubject": "EFS refresh completed",
  "SNSMessage": "EFS refresh completed successfully",
  "SNSSubjectFailure": "EFS refresh failed",
  "SNSMessageFailure": "EFS refresh failed",
  "TagApplication": "myapp",
  "TagEnvironment": "preprod",
  "Tags": {
    "Application": "myapp",
    "Environment": "preprod",
    "CostCenter": "12345"
  }
}
```

### Workflow and Parameter Interactions

The Step Function uses these parameters to execute the following workflow:

1. **Preparation**: Validates input parameters and computes derived values
2. **Source EFS Analysis**: Analyzes the source EFS file system
3. **Target EFS Creation/Update**: Creates a new EFS file system or updates an existing one
4. **Mount Target Configuration**: Configures mount targets in the specified subnets
5. **Backup Restoration**: Restores data from the source EFS to the target EFS
6. **Old EFS Management** (optional): Deletes the old EFS file system if specified
7. **Metadata Storage** (optional): Stores EFS metadata in SSM Parameter Store
8. **Finalization**: Updates DynamoDB tracking and sends SNS notifications

The Step Function automatically handles dependencies between these steps and ensures proper error handling throughout the process.

### Parameter Reference Table

| Parameter | Description | Required | Default |
|-----------|-------------|:--------:|:-------:|
| `SourceEFSName` | Name of the source EFS file system | Yes | - |
| `EFSName` | Name of the target EFS file system | Yes | - |
| `AWSBackupRoleArn` | ARN of the IAM role for AWS Backup | Yes | - |
| `Encrypted` | Whether the file system should be encrypted | Yes | - |
| `KmsKeyId` | ID of the KMS key for encryption | No | - |
| `newFileSystem` | Whether to create a new file system | Yes | - |
| `DeleteOldEfs` | Whether to delete the old file system | No | false |
| `EFSLifecyclePolicies` | Lifecycle policies for the file system | Yes | - |
| `LambdaEfsFunction` | Name of the Lambda function for EFS operations | Yes | - |
| `StoreEfsMetadataInSSM` | Whether to store EFS metadata in SSM | No | false |
| `EfsIdSSMParameterName` | Name of the SSM parameter for the EFS ID | No | - |
| `EfsSubPathSSMParameterName` | Name of the SSM parameter for the EFS sub-path | No | - |
| `SecurityGroupID` | List of security group IDs | Yes | - |
| `SubnetIDs` | List of subnet IDs | Yes | - |
| `DynamoDBTableName` | Name of the DynamoDB table to store refresh state | Yes | - |
| `SNSTopicArn` | ARN of the SNS topic for notifications | Yes | - |
| `SNSSubject` | Subject of the SNS message in case of success | Yes | - |
| `SNSMessage` | Body of the SNS message in case of success | Yes | - |
| `SNSSubjectFailure` | Subject of the SNS message in case of failure | Yes | - |
| `SNSMessageFailure` | Body of the SNS message in case of failure | Yes | - |
| `TagApplication` | Value of the Application tag | Yes | - |
| `TagEnvironment` | Value of the Environment tag | Yes | - |
| `Tags` | Map of tags to apply to resources | Yes | - |
| `ItemsToRestore` | List of items to restore | No | - |

## Running the Step Function

The module includes a shell script `run_efs_refresh.sh` that can be used to launch the Step Function with a JSON input file:

```bash
./run_efs_refresh.sh --name RefreshEnvEfsMyAppPreprod --input efs_refresh_input.json
```

Options:
- `-n, --name NAME`: Name of the Step Function (required)
- `-i, --input FILE`: JSON input file (required)
- `-p, --profile PROFILE`: AWS profile to use (optional)
- `-r, --region REGION`: AWS region (optional, default: eu-west-3)
- `-h, --help`: Display help information

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.1.0 |
| aws | >= 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| archive | n/a |
| aws | >= 3.0.0 |
| local | n/a |
| null | n/a |

## Inputs

**Note**: Most of the configuration for the EFS refresh operation is now provided via the JSON input file to the Step Function, not through Terraform variables. The Terraform module only sets up the infrastructure needed to run the refresh operations.

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| app_name | Application name for tagging resources | `string` | n/a | yes |
| env_name | Environment name for tagging resources | `string` | n/a | yes |
| vpc_id | The VPC ID where Lambda functions will be deployed | `string` | n/a | yes |
| private_subnets_ids | List of private subnet IDs where Lambda functions will be deployed | `list(string)` | n/a | yes |
| create_s3_bucket | Whether to create an S3 bucket for storing input files | `bool` | `false` | no |
| s3_bucket_name | Name of the S3 bucket to create or use for storing input files | `string` | `null` | no |
| put_step_function_input_json_files_on_s3 | Whether to upload example JSON input files to the S3 bucket | `bool` | `false` | no |
| sns_topic_arn | ARN of an existing SNS topic for notifications (if not provided, a new one will be created) | `string` | `null` | no |
| tags | Additional tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| iam_role_step_function | IAM role for Step Function |
| state_machine_name | Step Function state machine name |
| step_function_dynamodb_arn | DynamoDB table ARN for Step Function |
| step_function_json_files | Step Function input JSON files |
| step_function_sns_arn | SNS topic ARN for Step Function |
| vpc_security_group_for_lambda | Security group for Lambda functions |
