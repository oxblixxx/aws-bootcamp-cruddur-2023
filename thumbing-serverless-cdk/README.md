# Thumbing Serverless CDK

This directory contains the AWS Cloud Development Kit (CDK) application responsible for provisioning the infrastructure required for the image processing pipeline.

## Overview

The stack deploys a serverless image processing workflow using AWS services. Images uploaded to an S3 bucket are processed by an AWS Lambda function, and processed image uploads trigger Amazon SNS notifications to an external webhook.

## Architecture

```text
                    +----------------------+
                    |  Amazon S3 Bucket    |
                    |                      |
                    | avatars/original/*   |
                    +----------+-----------+
                               |
                               | ObjectCreated
                               ▼
                     +----------------------+
                     |    AWS Lambda        |
                     |  Image Processing    |
                     +----------+-----------+
                               |
                               | Writes resized image
                               ▼
                    +----------------------+
                    |  Amazon S3 Bucket    |
                    |                      |
                    | avatars/processed/*  |
                    +----------+-----------+
                               |
                               | ObjectCreated
                               ▼
                     +----------------------+
                     |      Amazon SNS      |
                     +----------+-----------+
                               |
                               | HTTPS Subscription
                               ▼
                     External Webhook Endpoint
```

## Resources Created

The CDK stack provisions or configures the following resources:

* AWS Lambda function for image processing
* Amazon SNS Topic
* SNS HTTPS Subscription
* Amazon S3 Event Notifications
* IAM permissions for Lambda to read and write objects in S3

> **Note:** The S3 bucket is imported into the stack rather than created. The `createBucket()` helper exists for development purposes but is not currently used.

## Infrastructure Flow

1. A user uploads an image to the input folder.
2. Amazon S3 emits an `ObjectCreated` event.
3. The Lambda function downloads the image.
4. The image is resized using the `sharp` library.
5. The processed image is uploaded to the output folder.
6. Uploading the processed image triggers another S3 event.
7. Amazon SNS publishes a notification.
8. The SNS topic forwards the notification to the configured webhook endpoint.

## Environment Variables

The CDK application loads its configuration from a `.env` file located in the project root.

| Variable                    | Description                         |
| --------------------------- | ----------------------------------- |
| `THUMBING_BUCKET_NAME`      | Existing S3 bucket name             |
| `THUMBING_S3_FOLDER_INPUT`  | Folder containing original images   |
| `THUMBING_S3_FOLDER_OUTPUT` | Folder for processed images         |
| `THUMBING_WEBHOOK_URL`      | HTTPS endpoint subscribed to SNS    |
| `THUMBING_TOPIC_NAME`       | SNS topic name                      |
| `THUMBING_FUNCTION_PATH`    | Path to the Lambda source directory |

Example:

```env
THUMBING_BUCKET_NAME=assets.mustaphaops.online
THUMBING_S3_FOLDER_INPUT=avatars/original
THUMBING_S3_FOLDER_OUTPUT=avatars/processed
THUMBING_TOPIC_NAME=image-processing-topic
THUMBING_WEBHOOK_URL=https://example.com/webhook
THUMBING_FUNCTION_PATH=../lamda/process-images
```

## IAM Permissions

The Lambda execution role is granted permission to:

* `s3:GetObject`
* `s3:PutObject`

for all objects within the configured S3 bucket.

## Lambda Configuration

The deployed Lambda uses:

* Runtime: Node.js 20.x
* Handler: `index.handler`

Environment variables are injected during deployment to configure:

* Destination bucket
* Input folder
* Output folder
* Image width
* Image height

## Deployment

Install project dependencies:

```bash
npm install
```

Bootstrap the AWS environment (first deployment only):

```bash
npx cdk bootstrap
```

Preview infrastructure changes:

```bash
npx cdk diff
```

Deploy the stack:

```bash
npx cdk deploy
```

Destroy the stack:

```bash
npx cdk destroy
```

## Project Structure

```text
thumbing-serverless-cdk/
├── bin/
│   └── thumbing-serverless-cdk.ts
├── lib/
│   └── thumbing-serverless-cdk-stack.ts
├── cdk.json
├── package.json
├── tsconfig.json
└── .env
```

## Design Notes

* The S3 bucket is imported instead of created, allowing the infrastructure to integrate with an existing bucket.
* Helper methods are used to keep the stack modular and improve readability.
* Infrastructure responsibilities are separated into reusable methods for creating Lambda functions, SNS resources, IAM policies, and S3 notifications.
* Runtime configuration is provided through environment variables rather than hardcoded values.

## Future Improvements

Potential enhancements include:

* Uploading Lambda artifacts through Amazon S3 during deployment.
* Dead Letter Queue (DLQ) support for failed Lambda invocations.
* CloudWatch alarms and dashboards.
* AWS X-Ray tracing.
* Structured logging with CloudWatch Logs Insights.
* Parameter Store or AWS Secrets Manager for configuration management.
* Unit and integration tests using the AWS CDK Assertions library.
* Image format conversion (WebP, AVIF).
* Support for multiple image sizes generated from a single upload.

## Technologies

* AWS CDK (TypeScript)
* AWS Lambda
* Amazon S3
* Amazon SNS
* AWS IAM
* Node.js 20
* TypeScript
