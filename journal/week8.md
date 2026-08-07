# Week 8 — Serverless Image Processing

Created a s3 bucket over the console with a folder named avatar and two sub-folders originals and processed.
mkdir thumbing-serverless-cdk
cd `thumbing-serverless-cdk`
npm install -g aws-cdk
cdk init app --language typescript

create a lamda folder for process-image in `aws` directory

cd `thumbing-serverless-cdk`

npm init -y


https://sharp.pixelplumbing.com/install/#aws-lambda
npm install sharp

npm i @aws-sdk/client-s3
npm i dotenv


npx cdk --version
npx cdk bootstrap

Then the cdk code is deployed in 
`thumbing-serverless-cdk/bin/thumbing-serverless-cdk-stack.ts`. The goal is to set up a serverless image processing, where images uploaded to an S3 bucket are processed by an AWS Lambda function, and processed image uploads trigger Amazon SNS notifications to an external webhook. Read the [README.md](thumbing-serverless-cdk/README.md) to understand the architecture. Also the lamda function resides in [lamda-path](aws/lamda/process-images). The [README.md](aws/lamda/process-images/README.md) also explains how the functions works. For testing of the image, a script is created in [S3](aws/s3), to handle assets upload and delete. To test the processed image after upload. 

```sh
npx cdk deploy
```

, after the deployment, the stack can be confirmed on the console in stackformation.

Then, upload assets with the s3 script

```sh
chmod +x aws/s3/copy-image
./aws/s3/copy-image
```

Then proceed to the s3 console and confirm that the image is been uploaded and that there is an image residing in the processed folder with the defined image aspect ratio. 

While images, needs to be served from Cloudfront, proceed to the console to create one, the console is easier as it automatically updates the s3 to give permissions for cloudfront to access it. 

While creating the cdn, choose the s3 and do not choose any path

put a domain, chaneg .env to upload.url and assets.url, seperate them, recopy the commit for setup cloudfront


So currently, aws couldnt allow me to create Cloudfront so, I opted for fastly, instead.

```
# Configuring Fastly as a CDN for a Private Amazon S3 Bucket Using AWS Signature Version 4 (SigV4)

## Overview

This guide demonstrates how to configure **Fastly** to serve content from a **private Amazon S3 bucket** without using CloudFront. Since the S3 bucket is private, Fastly must sign every request to Amazon S3 using **AWS Signature Version 4 (SigV4)**.

### Architecture

```text
                  Internet
                      │
                      ▼
        assets.mustaphaops.online
                      │
                      ▼
              Fastly Edge Network
        ┌──────────────────────────┐
        │ TLS Termination          │
        │ Edge Cache               │
        │ AWS SigV4 Signing (VCL)  │
        └────────────┬─────────────┘
                     │
                     ▼
      Private Amazon S3 Bucket (Origin)
```

---

# Prerequisites

* AWS Account
* Private S3 Bucket
* IAM User with programmatic access
* AWS Access Key ID
* AWS Secret Access Key
* Fastly Account
* Domain name

---

# Step 1 - Create the Private S3 Bucket

Create an S3 bucket.

Example:

```
assets.mustaphaops.online
```

Keep:

* Block Public Access = Enabled
* Bucket is Private

---

# Step 2 - Create an IAM User

Create an IAM user that Fastly will use.

Example policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "FastlyReadOnly",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::assets.mustaphaops.online",
                "arn:aws:s3:::assets.mustaphaops.online/*"
            ]
        }
    ]
}```

Generate:

* Access Key
* Secret Key

These credentials will be used inside the VCL.

---

# Step 3 - Create a Fastly Service

Create a new CDN Service.

---

# Step 4 - Configure the Backend

Create one backend.

Example configuration:

| Setting              | Value                                                                                        |
| -------------------- | -------------------------------------------------------------------------------------------- |
| Address              | assets.mustaphaops.online.s3.us-east-1.amazonaws.com                                         |
| Port                 | 443                                                                                          |
| TLS to Origin        | Yes                                                                                          |
| Override Host        | assets.mustaphaops.online.s3.us-east-1.amazonaws.com                                         |
| SNI Hostname         | assets.mustaphaops.online.s3.us-east-1.amazonaws.com                                         |
| Certificate Hostname | s3.us-east-1.amazonaws.com *(or the value that successfully validates for your environment)* |
| Verify Certificate   | Yes                                                                                          |

> **Important:** All regional endpoints must match your bucket's actual AWS region.

---

# Step 5 - Add the AWS SigV4 VCL

Create a **VCL Snippet**.

Subroutine:

```
vcl_miss
```

Do **NOT** place it inside:

```
vcl_recv
```

because `bereq` does not exist there.

Paste the [AWS Signature Version 4 VCL](https://www.fastly.com/documentation/solutions/examples/using-s3-compatible-buckets-as-private-origins/).

Replace:

* AWS Access Key
* AWS Secret Key
* Bucket Name
* Region

with your own values.

---

# Step 6 - Configure the Domain

Add the domain:

```
assets.mustaphaops.online
```

Fastly will request domain ownership verification.

---

# Step 7 - Create the ACME Validation Record

Fastly provides a record similar to:

```
_acme-challenge.assets

CNAME

xxxxxxxx.fastly-validations.com
```

Create this DNS record.

Wait until Fastly issues the TLS certificate.

---

# Step 8 - Point the Domain to Fastly

Create:

```
Type:
CNAME

Host:
assets

Target:
global.prod.fastly.net
```

Once DNS propagates:

```
https://assets.mustaphaops.online
```

will route through Fastly.

---

# Step 9 - Activate the Service

Activate the latest Fastly configuration version.

---

# Troubleshooting

---

## Problem 1

### Error

```
Unknown variable bereq
```

### Cause

The SigV4 VCL was placed inside:

```
vcl_recv
```

`bereq` is unavailable in this subroutine.

### Fix

Move the snippet to:

```
vcl_miss
```

---

## Problem 2

### Error

```
Backend host could not be resolved
```

### Cause

Incorrect backend hostname.

Example:

```
wrong-bucket.s3.amazonaws.com
```

### Fix

Use the regional endpoint.

Example:

```
bucket-name.s3.us-east-1.amazonaws.com
```

---

## Problem 3

### Error

```
503 No healthy IP available for the backend
```

### Cause

Fastly could not successfully connect to the configured origin.

Possible causes:

* Wrong backend hostname
* Wrong AWS region
* TLS configuration mismatch
* Invalid backend configuration

### Resolution

Verify:

```
nslookup bucket.s3.us-east-1.amazonaws.com
```

Ensure all backend settings reference the correct regional endpoint.

---

## Problem 4

### Error

```
503 hostname doesn't match against certificate
```

### Cause

Fastly rejected the TLS certificate presented by Amazon S3 because the configured certificate hostname did not match the certificate.

### Resolution

Inspect the certificate:

```bash
openssl s_client \
-connect bucket.s3.us-east-1.amazonaws.com:443 \
-servername bucket.s3.us-east-1.amazonaws.com
```

Inspect Subject Alternative Names:

```bash
openssl s_client \
-connect bucket.s3.us-east-1.amazonaws.com:443 \
-servername bucket.s3.us-east-1.amazonaws.com \
</dev/null 2>/dev/null | \
openssl x509 -noout -subject -issuer -ext subjectAltName
```

Ensure the backend's certificate verification settings match the certificate presented by Amazon S3.

---

## Problem 5

### Error

```
Page can't be reached
```

### Cause

The traffic CNAME was not created.

Only the ACME validation record existed.

### Fix

Create:

```
assets

CNAME

global.prod.fastly.net
```

---

## Problem 6

### DNS Works But 503 Persists

Verification:

```bash
nslookup assets.mustaphaops.online
```

Expected:

```
assets.mustaphaops.online
→ x.sni.global.fastly.net
```

If this works, DNS is no longer the problem.

Focus on the backend configuration.

---

# Useful Verification Commands

Verify bucket hostname:

```bash
nslookup assets.mustaphaops.online.s3.us-east-1.amazonaws.com
```

Verify bucket region:

```bash
aws s3api get-bucket-location \
--bucket assets.mustaphaops.online
```

Inspect S3 certificate:

```bash
openssl s_client \
-connect assets.mustaphaops.online.s3.us-east-1.amazonaws.com:443 \
-servername assets.mustaphaops.online.s3.us-east-1.amazonaws.com
```

Test Fastly:

```bash
curl -I https://assets.mustaphaops.online
```

---

# Final Validation Checklist

* ✓ Bucket is private.
* ✓ IAM user has `s3:GetObject`.
* ✓ Fastly backend points to the correct regional S3 endpoint.
* ✓ TLS to origin is enabled.
* ✓ AWS SigV4 VCL is placed in `vcl_miss`.
* ✓ Domain ownership is validated.
* ✓ Domain CNAME points to `global.prod.fastly.net`.
* ✓ Fastly service is activated.
* ✓ Content is served successfully through Fastly.

---

# Lessons Learned

This deployment demonstrates:

* Amazon S3 private origins
* AWS Signature Version 4 authentication
* Fastly VCL customization
* TLS troubleshooting
* DNS validation
* Custom CDN configuration
* Backend origin debugging
* Certificate validation
* Edge request signing
* CDN integration without CloudFront

This approach allows Fastly to securely access a private S3 bucket while keeping objects inaccessible directly from the public internet, providing a performant and secure alternative when CloudFront is unavailable or unsuitable.


```



Got an error while I set created the stack

aws lambda get-function-configuration \
  --function-name <your-lambda-name>


aws lambda get-function \
  --function-name ThumbingServerlessCdkStack-ThumbLambda5C775138-QtsSrqoWTNDk


curl -o lambda.zip ""

unzip lambda.zip, I inspected the zip file and couldn't find a js file


The fix is that, i didnt save index.js file, 






Error encountered

current credentials could not be used to assume 'arn:aws:iam::193654356005:role/cdk-hnb659fds-deploy-role-193654356005-us-east-1', but are for the right account. Proceeding anyway.
ThumbingServerlessCdkStack: SSM parameter /cdk-bootstrap/hnb659fds/version not found. Has the environment been bootstrapped? Please run 'cdk bootstrap' (see https://docs.aws.amazon.com/cdk/latest/guide/bootstrapping.html)



"--require-approval" is enabled and stack includes security-sensitive updates: Do you wish to deploy these changes? (y/n) y
ThumbingServerlessCdkStack: deploying... [1/1]
[████████████████████▋·····································] (5/14)
5:45:54 PM | CREATE_FAILED           | AWS::SNS::Subscription        | ThumbingTopichttps...ooksavatar96308835
Resource handler returned message: "Invalid parameter: Unreachable Endpoint (Service: Sns, Status Code: 400, Request ID: 6867686f-8457-5692-8f85-0abc9f45eb6a) (SDK Attempt Count: 1)" (RequestToken: 30853684-df11-c21b-b391-cf102a2d6fbc, HandlerErrorCode: In
validRequest)

❌  ThumbingServerlessCdkStack failed: DeploymentError: Resource updates failed:
ThumbingServerlessCdkStack/ThumbingTopic/https:----api.mustaphaops.online--webhooks--avatar/Resource  (AWS::SNS::Subscription ThumbingTopichttpsapimustaphaopsonlinewebhooksavatar96308835)
  Resource handler returned message: "Invalid parameter: Unreachable Endpoint (Service: Sns, Status Code: 400, Request ID:
  6867686f-8457-5692-8f85-0abc9f45eb6a) (SDK Attempt Count: 1)" (RequestToken: 30853684-df11-c21b-b391-cf102a2d6fbc,
  HandlerErrorCode: InvalidRequest)
Source Location: ...WrappedClass.addSubscription in aws-cdk-lib...
                 ThumbingServerlessCdkStack.createSnsSubscription (/home/sutneppa/aws-bootcamp-cruddur-2023/thumbing-serverless-cdk/lib/thumbing-serverless-cdk-stack.ts:114:38)
                 new ThumbingServerlessCdkStack (/home/sutneppa/aws-bootcamp-cruddur-2023/thumbing-serverless-cdk/lib/thumbing-serverless-cdk-stack.ts:39:10)
                 <anonymous> (/home/sutneppa/aws-bootcamp-cruddur-2023/thumbing-serverless-cdk/bin/thumbing-serverless-cdk.ts:6:1)
                 <anonymous> (/home/sutneppa/aws-bootcamp-cruddur-2023/thumbing-serverless-cdk/bin/thumbing-serverless-cdk.ts:20:2)

MY ENDPOINT WAS DOWN HERE, so i brought it up


```
2026-07-16T18:56:27.811Z
2026-07-16T18:56:27.811Z	undefined	ERROR	Uncaught Exception 	
{
    "errorType": "Error",
    "errorMessage": "Could not load the \"sharp\" module using the linux-x64 runtime\nERR_DLOPEN_FAILED: /lib64/libm.so.6: version `GLIBC_2.27' not found (required by /var/task/node_modules/@img/sharp-linux-x64/lib/../../sharp-libvips-linux-x64/lib/libvips-cpp.so.8.18.3)\nPossible solutions:\n- Please upgrade Node.js:\n    Found 18.20.8\n    Requires >=20.9.0\n- Consult the installation documentation:\n    See https://sharp.pixelplumbing.com/install",
    "stack": [
        "Error: Could not load the \"sharp\" module using the linux-x64 runtime",
        "ERR_DLOPEN_FAILED: /lib64/libm.so.6: version `GLIBC_2.27' not found (required by /var/task/node_modules/@img/sharp-linux-x64/lib/../../sharp-libvips-linux-x64/lib/libvips-cpp.so.8.18.3)",
        "Possible solutions:",
        "- Please upgrade Node.js:",
        "    Found 18.20.8",
        "    Requires >=20.9.0",
        "- Consult the installation documentation:",
        "    See https://sharp.pixelplumbing.com/install",
        "    at Object.<anonymous> (/var/task/node_modules/sharp/dist/sharp.cjs:171:9)",
        "    at Module._compile (node:internal/modules/cjs/loader:1364:14)",
        "    at Module._extensions..js (node:internal/modules/cjs/loader:1422:10)",
        "    at Module.load (node:internal/modules/cjs/loader:1203:32)",
        "    at Module._load (node:internal/modules/cjs/loader:1019:12)",
        "    at Module.require (node:internal/modules/cjs/loader:1231:19)",
        "    at require (node:internal/modules/helpers:177:18)",
        "    at Object.<anonymous> (/var/task/node_modules/sharp/dist/constructor.cjs:10:1)",
        "    at Module._compile (node:internal/modules/cjs/loader:1364:14)",
        "    at Module._extensions..js (node:internal/modules/cjs/loader:1422:10)"
    ]
}
```

Got this error, I simply changed the `runtime: lambda.Runtime.NODEJS_18_X`  to `runtime: lambda.Runtime.NODEJS_20_X`. This was because of sharp dependecies






create and avatar  bucket, change name to upload bucket, change .env and .env.example