# Process Images Lambda

This directory contains the AWS Lambda function responsible for processing uploaded images.

## Overview

The Lambda function is triggered by Amazon S3 whenever a new image is uploaded to the configured input folder. It performs the following tasks:

1. Receives the S3 ObjectCreated event.
2. Downloads the original image from the source bucket.
3. Resizes the image using the `sharp` library.
4. Uploads the processed image to the configured output folder within the destination bucket.

## Directory Structure

```text
process-images/
├── index.js                  # Lambda entry point
├── s3-image-processing.js    # Image processing and S3 helper functions
├── package.json
├── package-lock.json
├── example.json              # Sample S3 event for local testing
├── test.js                   # Local testing script
└── node_modules/
```

## Environment Variables

The Lambda expects the following environment variables to be configured by AWS CDK during deployment.

| Variable           | Description                                             |
| ------------------ | ------------------------------------------------------- |
| `DEST_BUCKET_NAME` | Destination S3 bucket where processed images are stored |
| `FOLDER_INPUT`     | Source folder containing uploaded images                |
| `FOLDER_OUTPUT`    | Destination folder for processed images                 |
| `PROCESS_WIDTH`    | Output image width (pixels)                             |
| `PROCESS_HEIGHT`   | Output image height (pixels)                            |

Example:

```text
DEST_BUCKET_NAME=assets.mustaphaops.online
FOLDER_INPUT=avatars/original
FOLDER_OUTPUT=avatars/processed
PROCESS_WIDTH=512
PROCESS_HEIGHT=512
```

> **Note:** Environment variables are injected by the CDK stack during deployment and should not be hardcoded into the application.

## Deployment

This Lambda is deployed as part of the AWS CDK infrastructure.

Deploy the stack from the CDK project root:

```bash
npx cdk deploy
```

## Trigger

The function is invoked automatically by Amazon S3 when an object is created in the configured input folder.

Example:

```text
avatars/original/profile.jpg
```

The processed image is written to:

```text
avatars/processed/profile.jpg
```

## Local Development

Install dependencies:

```bash
npm install
```

Run local tests:

```bash
node test.js
```

A sample S3 event payload is available in `example.json` for testing.

## Dependencies

* Node.js 20.x (recommended)
* sharp
* AWS SDK for JavaScript v3

## Workflow

```text
User Upload
      │
      ▼
Amazon S3 (Input Folder)
      │
      ▼
S3 ObjectCreated Event
      │
      ▼
AWS Lambda
      │
      ├── Download Original Image
      ├── Resize Image (Sharp)
      └── Upload Processed Image
      │
      ▼
Amazon S3 (Output Folder)
```

## Notes

* Images are processed in-memory without using temporary storage.
* The destination image is stored in JPEG format.
* The Lambda execution role must have permission to read from the source bucket and write to the destination bucket.
* The `sharp` dependency should be built for the same runtime as the Lambda function (for example, Node.js 20 on Amazon Linux) to avoid native library compatibility issues.
