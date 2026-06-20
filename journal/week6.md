# Week 6 — Deploying Containers
#### WHAT TO DELETE
1) LOG 
2) DELETE CLUSTER

Added test scripts, why? this will be used to test in the db from the backend container, we wont want to add network utilities or unnecessary package in the container. `backend-flask/bin/db`
```sh
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

also add health check in app.py

```py
@app.route('/api/health-check')
def health_check():
  return {'success': True}, 200

```


add this in bin/flask
```sh
#!/usr/bin/env python3

import urllib.request

response = urllib.request.urlopen('http://localhost:4567/api/health-check')
if response.getcode() == 200:
  print("Flask server is running")
else:
  print("Flask server is not running")
```


# https://docs.aws.amazon.com/cli/latest/reference/logs/create-log-group.html
# https://docs.aws.amazon.com/cli/latest/reference/logs/put-retention-policy.html
Create cloudwatch logs for the ecs to use, this is a pre-requiste

```sh
aws logs create-log-group --log-group-name "/cruddur/ecr-fargate"
aws logs put-retention-policy --log-group-name "/cruddur/ecr-fargate" --retention-in-days 1
``


Then setup ecr,fetch aws account ID and region THEN SET IT UP AS ENV

```
export AWS_ACCOUNT_ID=193654356005
export AWS_DEFAULT_REGION=us-east-1
```

Then run this command 

```sh
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
```

On succesful login, it should popup login succeeded.

Then create a repository

```sh
aws ecr create-repository \
  --repository-name cruddur-python \
  --image-tag-mutability MUTABLE
```

Set the repository url in env
```sh
export ECR_PYTHON_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/cruddur-python"
echo $ECR_PYTHON_URL
```

Then pull the base image for python and tag it, then push to the created ECR
```sh
docker pull python:3.10-slim-buster
docker tag python:3.10-slim-buster $ECR_PYTHON_URL:3.10-slim-buster
docker push $ECR_PYTHON_URL:3.10-slim-buster
```
Then create ecr repo, rebuild the backend image by change the base image in the Dockerfile to the 
GOT THIS UPON PUSHING TO ECR_PYTHON_URL pushed to ECR.

Create the image
```sh
aws ecr create-repository \
  --repository-name backend-flask \
  --image-tag-mutability MUTABLE
```

Export ENV
```sh
export ECR_BACKEND_FLASK_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/backend-flask"
echo $ECR_BACKEND_FLASK_URL
```

Rebuild the image and tag

```sh
docker build -t backend-flask .
docker tag backend-flask:latest $ECR_BACKEND_FLASK_URL:latest

```

Push the image

```sh
docker push $ECR_BACKEND_FLASK_URL:latest
```

i Info → Not all multiplatform-content is present and only the available single-platform image was pushed
         sha256:37aa274c2d001f09b14828450d903c55f821c90f225fdfdd80c5180fcca77b3f -> sha256:68f714f81d6522d6ad2156abee2535307c2be24a96781f4823c06422dfff3a2c



The create Paramaters, parameters is a way to handle secrets spend free, instead of AWS secrets manager. Navigate to system manager. 


```sh
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_ACCESS_KEY_ID" --value $AWS_ACCESS_KEY_ID
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_SECRET_ACCESS_KEY" --value $AWS_SECRET_ACCESS_KEY
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/CONNECTION_URL" --value $PROD_CONNECTION_URL
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN" --value $ROLLBAR_ACCESS_TOKEN
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS" --value "x-honeycomb-team=$HONEYCOMB_API_KEY"
```






To create a cluster, run the linked role via the cli first

```sh
aws iam create-service-linked-role \
--aws-service-name ecs.amazonaws.com
```

Also create 2 different policies
aws iam create-role \
  --role-name CruddurEcsTaskRole \
  --assume-role-policy-document file://trust-policy.json
This creates the trust

This creates this for reuse
  aws iam create-policy \
  --policy-name CruddurSSMAccess \
  --policy-document file://ssm-policy.json

Then later attach it to the create-role
aws iam attach-role-policy \
  --role-name CruddurEcsTaskRole \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/CruddurSSMAccess

aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess --role-name ServiceExecutionRole

Then create a cluster

```sh
 aws ecs create-cluster \
--cluster-name cruddur \
--service-connect-defaults namespace=cruddur
```


Create parameter, this is cheaper compared to AWS KMS. Also ensure to set region in `aws configure` and to export env `export AWS_ACCESS_KEY_ID`.



# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/specifying-sensitive-data.html
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/secrets-envvar-ssm-paramstore.html
# https://docs.aws.amazon.com/cli/latest/reference/ssm/put-parameter.html

```sh
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_ACCESS_KEY_ID" --value $AWS_ACCESS_KEY_ID
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_SECRET_ACCESS_KEY" --value $AWS_SECRET_ACCESS_KEY
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/CONNECTION_URL" --value $PROD_CONNECTION_URL
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN" --value $ROLLBAR_ACCESS_TOKEN
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS" --value "x-honeycomb-team=$HONEYCOMB_API_KEY"
```


Now, to create a service, there needs to be task a defined already! Here is to create it.

aws ecs register-task-definition --cli-input-json file://aws/task-definitions/backend-flask.json


Then to create a service, it can be created over the console, but the console lacks a lot of features. 

```sh
aws ecs create-service --cli-input-json file://aws/json/service-backend-flask.json
```

Check the health status of the task, then allow 4567 in the security group for cruddur-service, then also allow 5432 from the cruddur-sg group in the default security group

export DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
--filters "Name=isDefault, Values=true" \
--query "Vpcs[0].VpcId" \
--output text)
echo $DEFAULT_VPC_ID


export DEFAULT_SUBNET_IDS=$(aws ec2 describe-subnets  \
 --filters Name=vpc-id,Values=$DEFAULT_VPC_ID \
 --query 'Subnets[*].SubnetId' \
 --output json | jq -r 'join(",")')
echo $DEFAULT_SUBNET_IDS



export CRUD_SERVICE_SG=$(aws ec2 describe-security-groups \
  --filters Name=group-name,Values=crud-srv-sg \
  --query 'SecurityGroups[*].GroupId' \
  --output text)
echo $CRUD_SERVICE_SG


ADD GETAUTHORIZATION, ECR POLICY IN EXECUTIONPOLICY

service backend-flask-service-eqwx9jnl was unable to place a task. Reason: ResourceInitializationError: unable to pull secrets or registry auth: execution resource retrieval failed: unable to retrieve ecr registry auth: service call has been retried 1 time(s): operation error ECR: GetAuthorizationToken, https response error StatusCode: 400, RequestID: 415e6826-9d7a-4ef1-8eea-8eec9105a1a8, api error AccessDeniedException: User: arn:aws:sts::193654356005:assumed-role/CruddurServiceExecutionRole/bc88e9b6acd947589d99b68067f8de59 is not authorized to perform: ecr:GetAuthorizationToken on resource: * because no identity-based policy allows the ecr:GetAuthorizationToken action.



Got this error while trying to use the `aws ecs execute-command`. The issue is that the feature can not be enabled via console, so creating the service via CLI is the fix
```sh
aws: [ERROR]: An error occurred (InvalidParameterException) when calling the ExecuteCommand operation: The execute command failed because execute command was not enabled when the task was run or the execute command agent isn't running. Wait and try again or run a new task with execute command enabled and try again.
```


```
portName(backend-flask) does not refer to any named PortMapping in the container definitions
```

Got this error, the error is from the task definition, I didn't map "containerPort" 4567, to a name"
ADDED BELOW TO FIX IT
```
          "name": "backend-flask",

``