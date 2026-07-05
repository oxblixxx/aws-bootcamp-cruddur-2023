# Week 6 — Deploying Containers to Amazon ECS

>This week documents the complete process of containerizing, publishing, and deploying the Cruddur application to Amazon ECS using Amazon ECR, CloudWatch Logs, AWS Systems Manager Parameter Store, IAM, and an Application Load Balancer (ALB).

---

# Table of Contents

* [Overview](#overview)
* [Prerequisites](#prerequisites)
* [Preparing the Backend Application](#preparing-the-backend-application)
* [Creating CloudWatch Log Groups](#creating-cloudwatch-log-groups)
* [Publishing Images to Amazon ECR](#publishing-images-to-amazon-ecr)
* [Storing Secrets with Parameter Store](#storing-secrets-with-parameter-store)
* [Creating IAM Roles and Policies](#creating-iam-roles-and-policies)
* [Creating an ECS Cluster](#creating-an-ecs-cluster)
* [Registering the ECS Task Definition](#registering-the-ecs-task-definition)
* [Creating the ECS Service](#creating-the-ecs-service)
* [Networking](#networking)
* [Security Groups](#security-groups)
* [Application Load Balancer](#application-load-balancer)
* [Troubleshooting](#troubleshooting)
* [Cleanup](#cleanup)

---

# Overview

The deployment architecture consists of:

```
Internet
      │
      ▼
Cloudflare (Optional)
      │
      ▼
Application Load Balancer
      │
      ▼
Amazon ECS Service
      │
      ▼
Backend Flask Container
      │
      ▼
PostgreSQL
```

The deployment uses:

* Amazon ECS
* Amazon ECR
* Amazon CloudWatch Logs
* AWS Systems Manager Parameter Store
* IAM Roles
* Application Load Balancer
* ECS Task Definitions

---

# Prerequisites

Before starting, the below where installed.

* AWS CLI installed
* Docker installed
* AWS credentials configured
* jq installed
* Python backend containerized
* Existing PostgreSQL database

Configure the AWS credentials:

```bash
aws configure
```

Export the required environment variables:

```bash
export AWS_ACCOUNT_ID=XXXXXXX
export AWS_DEFAULT_REGION=us-east-1
```

---

# Preparing the Backend Application

## Database Connectivity Test

Instead of installing database utilities inside the production container, a lightweight Python script is created for testing database connectivity.

**backend-flask/bin/db/test**

```python
#!/usr/bin/env python3

import psycopg
import os
import sys

connection_url = os.getenv("CONNECTION_URL")

conn = None
try:
  print('attempting connection')
  conn = psycopg.connect(connection_url)
  print("Connection successful!")
except psycopg.Error as e:
  print("Unable to connect to the database:", e)
finally:
  conn.close()
```

---

## Add a Health Check Endpoint

Add a simple endpoint for the backend to verify application health in `app.py`


```python
@app.route('/api/health-check')
def health_check():
    return {"success": True}, 200
```

---

## Flask Health Check Script

Create a script that verifies the Flask server is running.

**backend-flask/bin/flask/health-check**

```python
#!/usr/bin/env python3

import urllib.request

response = urllib.request.urlopen(
    "http://localhost:4567/api/health-check"
)

if response.getcode() == 200:
    print("Flask server is running")
else:
    print("Flask server is not running")
```

---

# Creating CloudWatch Log Groups

CloudWatch Log Groups must exist before ECS tasks can write logs.

Create the log group:

```bash
aws logs create-log-group \
    --log-group-name "/cruddur/ecs-fargate"
```

Configure log retention:

```bash
aws logs put-retention-policy \
    --log-group-name "/cruddur/ecs-fargate" \
    --retention-in-days 1
```

---

# Publishing Images to Amazon ECR

## Login to Amazon ECR

The AWS CLI retrieves a temporary authentication token and passes it securely to Docker without exposing the password in the terminal. Ensure the authenticated user has enough privileges

```bash
aws ecr get-login-password \
--region $AWS_DEFAULT_REGION \
| docker login \
--username AWS \
--password-stdin \
"$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
```

Expected output:

```
Login Succeeded
```

---

## Create the Python Base Image Repository

Create a repository for the base image of python.

```bash
aws ecr create-repository \
--repository-name cruddur-python \
--image-tag-mutability MUTABLE
```

Export the repository URL:

```bash
export ECR_PYTHON_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/cruddur-python"

echo $ECR_PYTHON_URL
```

Pull, tag, and push the base image:

```bash
docker pull python:3.10-slim-buster

docker tag python:3.10-slim-buster \
$ECR_PYTHON_URL:3.10-slim-buster

docker push $ECR_PYTHON_URL:3.10-slim-buster
```

---

## Create the Backend Repository

Also create the backend-flask repository 

```bash
aws ecr create-repository \
--repository-name backend-flask \
--image-tag-mutability MUTABLE
```

Export the repository URL:

```bash
export ECR_BACKEND_FLASK_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/backend-flask"

echo $ECR_BACKEND_FLASK_URL
```

Now before building the image, open the Dockerfile for the [backend-flask](backend-flask/Dockerfile) then replace the base image to the python base image repository url, from:

>FROM python:3.10-slim-buster

TO 

>FROM  $ECR_PYTHON_URL:3.10-slim-buster.

Replace $ECR_PYTHON_URL with the complete URL.

Then proceed to build the image:

```bash
docker build -t backend-flask .
```

Tag it:

```bash
docker tag backend-flask:latest \
$ECR_BACKEND_FLASK_URL:latest
```
Push it:

```bash
docker push $ECR_BACKEND_FLASK_URL:latest
```

---

## Create the Node Base Image Repository
Here, IMMUTABLE is used to figure how it works, while with a `MUTABLE` flag, the image can be over writen, an docker image with `nodejs:v1` on first push, will accept `nodejs:v1` on second push overwritten the first pushed image and `IMMUTABLE` An immutable repository does not allow an existing tag to be overwritten. The second push will have to be `nodejs:v2`

```bash
aws ecr create-repository \
  --repository-name cruddur-node \
  --image-tag-mutability IMMUTABLE

export ECR_NODE_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/cruddur-node"

docker pull node:16.18
docker tag node:16.18 $ECR_NODE_URL:node:16.18
docker push $ECR_NODE_URL:node:16.18
```

### Frontend React Image
The `npm start` command is intended for development. It launches the development server, which provides features such as hot module replacement (HMR), source maps, and live reloading. These features are useful during development but introduce unnecessary overhead and are not designed for production workloads.

Instead, the application is first built into optimized static assets using:

```bash
npm run build
```

The generated `dist/` directory is then copied into a webserver image, to serve the static files directly. 

Unlike the backend service, the frontend does not require sensitive information such as API keys or database credentials. Therefore, I passed the required configuration values into the Docker image during the build process using Docker's `ARG` and `ENV` instructions.

> **Note:** Before building the Docker image, ensure that all required environment variables have already been exported in your shell. These exported variables are referenced by the `docker build` command and passed into the image as build arguments.

```bash
aws ecr create-repository \
  --repository-name frontend-react \
  --image-tag-mutability MUTABLE

export ECR_BACKEND_REACT_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/frontend-react"

```sh
cd frontend-react
cp Dockerfile Dockerfile.prod
```

```sh
docker build \
--build-arg REACT_APP_BACKEND_URL="*" \
--build-arg REACT_APP_AWS_PROJECT_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_COGNITO_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_USER_POOLS_ID="--------" \
--build-arg REACT_APP_CLIENT_ID="---------" \
-t frontend-react:v1 \
-f Dockerfile.prod \
.

docker tag frontend-react:v1 $ECR_FRONTEND_REACT_URL:v1
docker push $ECR_FRONTEND_REACT_URL:v1
```

NGINX is the desired webserver in this setup.

# Storing Secrets with Parameter Store
Before creating the `TASK DEFINITION` paramaters should firstly be created so that it can be easily referenced in the respective json file. Instead of embedding secrets inside the task definition, AWS Systems Manager Parameter Store is used
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/specifying-sensitive-data.html
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/secrets-envvar-ssm-paramstore.html
# https://docs.aws.amazon.com/cli/latest/reference/ssm/put-parameter.html


```bash
aws ssm put-parameter \
--type SecureString \
--name "/cruddur/backend-flask/AWS_ACCESS_KEY_ID" \
--value $AWS_ACCESS_KEY_ID
```

```bash
aws ssm put-parameter \
--type SecureString \
--name "/cruddur/backend-flask/AWS_SECRET_ACCESS_KEY" \
--value $AWS_SECRET_ACCESS_KEY
```

```bash
aws ssm put-parameter \
--type SecureString \
--name "/cruddur/backend-flask/CONNECTION_URL" \
--value $PROD_CONNECTION_URL
```

```bash
aws ssm put-parameter \
--type SecureString \
--name "/cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN" \
--value $ROLLBAR_ACCESS_TOKEN
```

```bash
aws ssm put-parameter \
--type SecureString \
--name "/cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS" \
--value "x-honeycomb-team=$HONEYCOMB_API_KEY"
```

---

# Creating IAM Roles and Policies
For a newly created AWS Account, the `service-linked-role` needs to be created first.

## Create the ECS Service Linked Role

```bash
aws iam create-service-linked-role \
--aws-service-name ecs.amazonaws.com
```

---

## Create the ECS Task Role

```bash
aws iam create-role \
--role-name CruddurEcsTaskRole \
--assume-role-policy-document file://trust-policy.json
```

---

## Create the SSM Access Policy

```bash
aws iam create-policy \
--policy-name CruddurSSMAccess \
--policy-document file://ssm-policy.json
```

---

## Attach the Policy

```bash
aws iam attach-role-policy \
--role-name CruddurEcsTaskRole \
--policy-arn arn:aws:iam::ACCOUNT_ID:policy/CruddurSSMAccess
```

Attach CloudWatch permissions:

```bash
aws iam attach-role-policy \
--role-name ServiceExecutionRole \
--policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess
```

---

# Creating an ECS Cluster

```bash
aws ecs create-cluster \
--cluster-name cruddur \
--service-connect-defaults namespace=cruddur
```

---

# Registering the ECS Task Definition

Register the task definition, ensure the parameter values are set, here is the [directory](aws/ecs/task-definitions), reference the 

1. ECR IMAGE URL.:
2. CLOUDWATCH LOG GROUP
3. EXECUTIONER ROLE
4. TASK TOLE
5. HEALTCH CHECK

```bash
aws ecs register-task-definition \
--cli-input-json file://aws/task-definitions/backend-flask.json
```

Repeat the same command for frontend task-definition

```bash
aws ecs register-task-definition \
--cli-input-json file://aws/task-definitions/frontend-react.json
```

---

# Networking

Retrieve the default VPC, or the VPC to be used:

```bash
export DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
--filters Name=isDefault,Values=true \
--query "Vpcs[0].VpcId" \
--output text)

echo $DEFAULT_VPC_ID
```

Retrieve subnet IDs:

```bash
export DEFAULT_SUBNET_IDS=$(aws ec2 describe-subnets \
--filters Name=vpc-id,Values=$DEFAULT_VPC_ID \
--query 'Subnets[*].SubnetId' \
--output json \
| jq -r 'join(",")')

echo $DEFAULT_SUBNET_IDS
```

Create a Security group for the ECS. Since we are not connecting the ALB yet, allow inbound to `4567` and `3000` from `0.0.0.0/0`.

```sh
aws ec2 create-security-group \
  --group-name crud-srv-sg \
  --description "Security group for Cruddur ECS services" \
  --vpc-id $DEFAULT_VPC_ID
```

Allow ingress rule. Firstly retrieve the security group ID for the service

```sh
```bash
export CRUD_SERVICE_SG=$(aws ec2 describe-security-groups \
--filters Name=group-name,Values=crud-srv-sg \
--query 'SecurityGroups[*].GroupId' \
--output text)

echo $CRUD_SERVICE_SG
```

```sh
aws ec2 authorize-security-group-ingress \
  --group-id $CRUD_SERVICE_SG \
  --protocol tcp \
  --port 3000 \
  --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress \
  --group-id $CRUD_SERVICE_SG \
  --protocol tcp \
  --port 4567 \
  --cidr 0.0.0.0/0
```

# Creating the ECS Service

Create the ECS service: Firstly the backend service and frontend service is created, for ease debugging if there is a need, which is inevitable with the loadbalancer block in the json not created alongside at the first run, it was ommited. Here is the [directory](aws/ecs/service). Ensure to put the below:

1. CRUDDUR SERVICE SG ID
2. SUBNETS
3. LISTENING PORTS
4. NAMESPACE
5. TASK-DEFINITION NAME TO USE

## Creating the Backend Service
```bash
aws ecs create-service \
--cli-input-json file://aws/ecs/service/backend-flask.json
```

If there are no error and it returns a healthy state, check the public ip address attached to the container with the port number. 

>NB: For my case and to cut spend, RDS was destroyed prior to the beginning of this setup, INCASE THE RDS IS NOT RUNNING, THE SERVICE WILL RUN AS EXPECTED but the connection error will be logged on the ECS CONSOLE, HOWEVER WHILE FIRSTLY CREATING THE BACKEND ECS SERVICE  THE `CONNECTION_URL` PARAMETER, A CONNECTION STRING MUST HAVE BEEN PASSED TO HAVE ALLOWED THE ECS TO BE CREATED. SO, FOR EASE, I CREATED A RDS SCRIPT THAT [CREATES-RDS](aws/rds/create-rds) AND [DESTROYS RDS](aws/rds/delete-rds) INSTANCE, THE SCRIPT ALSO DELETE EXISTING PARAMETER FOR THE CONNECTION STRING AND ADDS THE NEW CONNECTION STRING AND RUNS THE SCHEMA LOAD TOO.


## Creating the Frontend Service

```bash
aws ecs create-service \
--cli-input-json file://aws/ecs/frontend-react.json
```

Observe the logs as well incase there is no error from the ECS SERVICE LOGS TABS.

After both services were created succesfully, then I proceeded to the creating the loadbalancer

# Application Load Balancer
While I was about creating the ALB, it was clear that I need to understand the flow of network. 

From the load balancer allow inbound:

* HTTP (80)
* HTTPS (443)

Allow outbound:

* ECS service ports only with the source targeting the cruddur-service-sg

```sh 
aws ec2 create-security-group \
  --group-name crud-alb-sg \
  --description "Security group for ALB" \
  --vpc-id $DEFAULT_VPC_ID
```

```sh
export CRUD_ALB_SG=$(aws ec2 describe-security-groups \
--filters Name=group-name,Values=crud-alb-sg \
--query 'SecurityGroups[*].GroupId' \
--output text)

echo $CRUD_ALB_SG
```

Then proceed to add the ingress rules

```sh
aws ec2 authorize-security-group-ingress \
  --group-id $CRUD_ALB_SG \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-id $CRUD_ALB_SG \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0
```

Then create the outbound rule to the `crud-srv-sg`
# https://docs.aws.amazon.com/cli/latest/reference/ec2/authorize-security-group-egress.html#examples
```sh
aws ec2 authorize-security-group-egress \
    --group-id "$CRUD_ALB_SG" \
    --ip-permissions "IpProtocol=tcp,FromPort=80,ToPort=80,UserIdGroupPairs=[{GroupId=$CRUD_SRV_SG}]"
```

### ECS Service

Update the ECS service to allow inbound from the ALB security group as the source:

* Backend (4567)
* Frontend (3000 or 8080)

Do **not** expose ECS containers directly to the internet.

```sh
aws ec2 authorize-security-group-ingress \
  --group-id $CRUD_SRV_SG \
  --protocol tcp \
  --port 4567 \
  --source-group $CRUD_ALB_SG
```

```sh
aws ec2 authorize-security-group-ingress \
  --group-id $CRUD_SRV_SG \
  --protocol tcp \
  --port 4567 \
  --source-group $CRUD_ALB_SG
```

Then delete the previously set rules, to allow inbound to `3000` and `4567` from `0.0.0.0/0`

---


## Database

Allow PostgreSQL (5432) **only** from the ECS service security group.

---

# NETWORK DESIGN

Configure:

* Internet-facing ALB
* HTTP Listener (80)
* HTTPS Listener (443)
* ACM Certificate
* Target Groups
* Access Logs to Amazon S3

Host-based routing example:

```sh
app.example.com
    │
    ▼
Frontend Target Group

api.example.com
    │
    ▼
Backend Target Group
```

## Configuring the Application Load Balancer

With both ECS services deployed, the next step was to configure an Application Load Balancer (ALB) to route incoming traffic to the appropriate service. I created a dedicated target group and listener for each application.

### Frontend Target Group

| Setting | Value |
|---------|-------|
| Target Type | IP Address |
| Protocol | HTTP |
| Port | 3000 |
| Health Check Path | `/` |
| VPC | `<your-vpc>` |

### Backend Target Group

| Setting | Value |
|---------|-------|
| Target Type | IP Address |
| Protocol | HTTP |
| Port | 4567 |
| Health Check Path | `/api/health-check` |
| VPC | `<your-vpc>` |

### Listener Configuration

Two listeners were configured on the ALB, each forwarding traffic to its respective target group.

| Listener | Forward To |
|----------|------------|
| HTTP :3000 | Frontend Target Group |
| HTTP :4567 | Backend Target Group |

Then the ALB is created with the above configuration.

Once the target groups were created, I retrieved their ARNs and updated the [load-balancer-configuration](aws/ecs/service/backend-loadbalancer-arn.json) used by the ECS services.



Although the filename references the backend service, this JSON file simply contains the load balancer configuration for whichever service is being updated. Before deploying a service, I modify the file with the appropriate:

- Target Group ARN
- Container name
- Container port

Rather than deleting and recreating the ECS service and updating ecs service json file with the loadbalancer block, I updated the process with the following script:

```sh
aws ecs update-service --cli-input-json file://aws/ecs/service/update-service-lb```

The script updates each ECS service with its corresponding load balancer configuration. It is executed once for the frontend service and once for the backend service.

## Verifying the Deployment

After both services have been updated successfully, I retrieved the ALB DNS name and access each application using its respective listener port.

| Service | URL |
|---------|-----|
| Frontend | `http://<ALB-DNS>:3000` |
| Backend | `http://<ALB-DNS>:4567` |

At this stage:

- Both applications should be reachable through the Application Load Balancer.
- The ALB performs health checks and routes traffic only to healthy ECS tasks.
- The ECS task IP addresses should no longer be accessed directly, as all client traffic is expected to flow through the ALB.

---


## Configuring HTTP and HTTPS for the Application Load Balancer

At this stage, my domain's DNS is managed by **Cloudflare**, not Amazon Route 53. Because of this, I configured the Application Load Balancer (ALB) to work with Cloudflare by pointing my domain directly to the ALB.

### Configuring HTTP (Port 80)

I created a new **HTTP listener** on port **80** for the ALB.

For the default action, I configured the listener to forward requests to the **Frontend Target Group**. This ensures that any request that does not match a listener rule is served by the frontend application.

After creating the listener, I configured two host-based routing rules.

| Priority | Condition | Host Header | Target Group |
|----------|-----------|-------------|--------------|
| 10 | Host Header | `example.com` | Frontend Target Group |
| 20 | Host Header | `api.example.com` | Backend Target Group |

> Replaced `example.com` and `api.example.com` my domain and subdomain.

With this configuration:

- Requests sent to the root domain are forwarded to the React frontend.
- Requests sent to the API subdomain are forwarded to the Flask backend.
- Any request that does not match a rule falls back to the default listener action which is frontend

---

## Configuring Cloudflare DNS

Since Cloudflare manages my DNS records, I needed to point my domain to the Application Load Balancer DNS.

I created the following **CNAME** records.

| Type | Name | Target |
|------|------|--------|
| CNAME | `@` or `www` | `<ALB DNS Name>` |
| CNAME | `api` | `<ALB DNS Name>` |

Both records point to the DNS name assigned to the Application Load Balancer.

After the DNS changes propagated, I was able to access both services over HTTP.

- `http://example.com` → Frontend
- `http://api.example.com` → Backend

At this point, everything was functioning correctly, but traffic was still unencrypted because HTTPS had not yet been configured.

---

## Requesting an SSL Certificate with AWS Certificate Manager

To enable HTTPS on the Application Load Balancer, I requested a public SSL/TLS certificate using AWS Certificate Manager (ACM).

During the certificate request, I selected:

- **Certificate Type:** Public Certificate
- **Validation Method:** DNS Validation

I included both domain names in the certificate request:

- `example.com`
- `api.example.com`

Because my DNS is hosted by Cloudflare instead of Route 53, ACM could not automatically validate ownership of the domains. Instead, ACM generated DNS validation records.

For each domain, ACM provided:

- A CNAME record name
- A CNAME record value

I copied these records into Cloudflare's DNS configuration.

After the DNS records propagated, ACM successfully validated ownership of both domains and automatically issued the certificate.

---

## Associating the Certificate with the Application Load Balancer

Once the certificate status changed to **Issued**, I returned to the Application Load Balancer configuration.

I then:

1. Created an HTTPS listener on **port 443**.
2. Selected the ACM certificate that had just been issued.
3. Configured the listener with the same routing behavior as the HTTP listener.
4. Reused the existing host-based listener rules to forward requests to the appropriate target groups.

At this point, the Application Load Balancer was capable of serving encrypted HTTPS traffic for both the frontend and backend applications.

The final architecture is shown below.

```text
Internet
        │
        ▼
   Cloudflare DNS
        │
        ▼
Application Load Balancer
        │
   ┌────┴────┐
   │         │
Host: example.com        Host: api.example.com
        │                         │
        ▼                         ▼
Frontend Target Group      Backend Target Group
        │                         │
React ECS Service         Flask ECS Service
```

With this configuration, Cloudflare handles DNS resolution, the Application Load Balancer terminates TLS using the ACM certificate, and host-based routing directs requests to the appropriate ECS service.

While this isn't sufficient, anyone with my ALB DNS can create a CNAME and point to my domain, I will fix this issue going forward and also move my domain to Route 53 as well.




## Cost Optimization

To minimize AWS costs while working through the project, I automated the creation and deletion of the Application Load Balancer and some other services.

A deployment information file within the `aws` directory stores important resources created during deployment, including:

- Application Load Balancer ARN
- Application Load Balancer DNS name
- Frontend Target Group ARN
- Backend Target Group ARN
- And other services

### Why only the ALB is deleted

The Application Load Balancer incurs hourly charges, whereas target groups and listeners do not incur additional standalone charges. Because of this, my automation deletes only the ALB while preserving the existing target groups and listeners.

Keeping the target groups intact provides several advantages:

- Their ARNs remain unchanged.
- The ECS services do not require their load balancer configuration to be updated each time the ALB is recreated.
- Rebuilding the environment becomes significantly faster.
- Infrastructure costs are reduced when the environment is idle.

This workflow allows me to shut down the expensive components whenever I am not actively developing and recreate the load balancer in a matter of seconds when I need to continue working.

Then I fetched both TARGET GROUP ARNS AND UPDATED IN THIS [FILE](aws/ecs/service/backend-loadbalancer-arn.json). It's a json file, that only has the loadbalancer information, it will be modified for each service, respective port number and name. Then I automated added a [script](aws/ecs/service/update-service-lb) that updates the service respectively. The script will be ran one after the other.


After succesful service update, then proceed to the created ALB DNS name and put it in your browser and set it to there respective port number, if everything goes well, both services should be accessible from the ALB alone and not reachable anymore from the service container ip address. 

---


# Troubleshooting

## ECS Cannot Pull Image

**Error**

```
service backend-flask-service-eqwx9jnl was unable to place a task. Reason: ResourceInitializationError: unable to pull secrets or registry auth: execution resource retrieval failed: unable to retrieve ecr registry auth: service call has been retried 1 time(s): operation error ECR: GetAuthorizationToken, https response error StatusCode: 400, RequestID: 415e6826-9d7a-4ef1-8eea-8eec9105a1a8, api error AccessDeniedException: User: arn:aws:sts::193654356005:assumed-role/CruddurServiceExecutionRole/bc88e9b6acd947589d99b68067f8de59 is not authorized to perform: ecr:GetAuthorizationToken on resource: * because no identity-based policy allows the ecr:GetAuthorizationToken action.
```

### Cause

The ECS execution role lacks ECR permissions.

### Solution

Attach the required ECR permissions to the execution role.

---

## Execute Command Failed

**Error**

```
aws: [ERROR]: An error occurred (InvalidParameterException) when calling the ExecuteCommand operation: The execute command failed because execute command was not enabled when the task was run or the execute command agent isn't running. Wait and try again or run a new task with execute command enabled and try again.
```

### Cause

Execute Command was not enabled during service creation.

### Solution

Recreate the ECS service with Execute Command enabled using the AWS CLI.



---

## Port Mapping Error

**Error**

```
portName(backend-flask)
does not refer to any named PortMapping
```

### Cause

The container port mapping did not include a name.

### Solution

Add:

```json
"name": "backend-flask"
```

to the port mapping in the task definition.

---

## ECS Task Cannot Retrieve Secrets

Verify:

* IAM permissions
* SSM Parameter names
* Region
* Execution role
* Task role

---

## ECS Task Cannot Connect to Database

Verify:

* Security Groups
* PostgreSQL inbound rule
* Connection URL
* Database availability

Use the `bin/db` utility to verify connectivity.

---

# Cleanup

Delete resources when finished:

* ECS Service
* ECS Cluster
* ECR Images
* CloudWatch Log Groups
* Unused Security Groups
* Load Balancer
* Target Groups
* IAM Policies (if no longer required)

---

# Notes

* Use Parameter Store instead of hardcoding secrets.
* Build and push images before creating the ECS service.
* Register a new task definition revision after every image update.
* Prefer the AWS CLI over the Console for reproducible deployments.
* Enable CloudWatch Logs for easier troubleshooting.
* Configure health checks to allow ECS and the ALB to detect unhealthy tasks automatically.
