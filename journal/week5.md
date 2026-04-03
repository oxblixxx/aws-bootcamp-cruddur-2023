# Week 5 — DynamoDB and Serverless Caching
This week focused on integrating AWS services into the backend, specifically DynamoDB, Lamda, Cognito, and improving development workflows using GitHub Codespaces. The goal was to build scalable data handling, automate scripts, and streamline the development environment.

## ⚙️ Environment Setup
### 1. Update Dependencies
Added Boto3 to the project dependencies: Updated requirements.txt:

```py
boto3
python-jose
```

### 2. DevContainer Configuration

Updated .devcontainer to improve developer experience:

Export local database connection:
```sh
export CONNECTION_URL="postgresql://postgres:password@localhost:5432"
```
Automatically install dependencies on container start:

```sh
pip install -r requirements.txt
```
Changes for this were made in `.devcontainer/devcontainer.json`

## 3. AWS Credentials Injection

To securely manage credentials. Github Codespaces secrets is used to inject into the environment Secrets 


### Used GitHub Codespaces Secrets
Steps:
- Go to Avatar → Settings → Codespaces (Code, planning, and automation)

- Add secrets (e.g., AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
- Assign them to the repository

## 🗄️ DynamoDB Setup
Already DynamoDB exists in docker compose file and requires AWS logged via terminal to enable interaction. 

### 1. Ensure DynamoDB is Running
Run `sudo docker ps` to confirm DynamoDB is running.

### 2. Create DDB Utility Scripts
Scripts are created in the [backend-directory](backend-flask/bin/ddb). To do as follow:
- drop-table
- schema-load
- list-tables
- seed {TO SEED THE DUMMY CONVERSATIONS}
- scan {TO CHECK THE SEEDED DATA}

The script can be executed as it's in order above. Seed script comes after schema-load.

### 3. Schema Load

The schema-load script is responsible for creating tables:

```sh
./schema-load
```

Creates tables in local environment
Verify with:

```sh
./list-tables
```

### 4. Access Patterns Implementation

Designed access patterns scripts to optimize **Amazon DynamoDB queries:
- Query by user
- Query by message group
- Efficient key design for scalability
Here is where the [pattern-script](backend-flask/bin/ddb/patterns) is situated.

### 5. Application Refactoring
The [DynamoDB-logic](backend-flask/lib/ddb.py) is centralized to communicate with both local DynamoDB and production ready DynamoDB, if an environment `AWS_ENDPOINT_URL: "http://dynamodb-local:8000"` is set in docker-compose file, then it automatically integrates with local DynamoDB, otherwise, it interacts with production. The created scripts, can be executed against both environment. When this is executed `./schema-load`, this integrates with local dynamo db, but when prod attribute is set, it communicates with prod Dynamo db `./schema-load prod`.

Also the [main_logic_app](backend-flask/app.py) is updated also with AWS Cognito Integration, Updated message grouping logic under services to enabled chat initiation via route `/messages/new/<username>`


### Integrated **Amazon Cognito for user management.
Utility scripts were created to:
- List users:
  - Update Cognito user ID:
  - update_cognito_user_id

### Local Setup, Seeding, and DynamoDB Integration
####  1. Build Application Images
From the project root directory run the image build script:

```sh
source .devcontainer/image_build.sh
```
This builds both the frontend and backend Docker images.

#### 2. Verify Environment Configuration

Open the docker-compose.yml file and confirm:

```sh
AWS_ENDPOINT_URL
```
is set.

This is required for connecting to local DynamoDB. Also ensure the following are correctly set in your .env file:

- Cognito environment variables
- CONNECTION_URL
- AWS_SECRETS

#### 3. Check the seeded data
During Week 4, some users signed up on the Cruddur app. To reflect these users in the local database, follow the steps below:

Navigate to:

```sh
backend-flask/db/seed.sql
```

>Replace the placeholder values with the corresponding user details from Cognito.

This ensures that authenticated users are properly represented in the database.


#### 4. Bring up the project
Before starting Docker:

Split your terminal into two panes

In the second terminal:

```sh
cd backend-flask/bin/db
chmod +x .
```

This makes all the file executable, as they are scripts.

In the first terminal:

```sh
docker compose up
```

Return to the second pane

```sh
./load
```

This script creates the cruddur database.
It prevents the backend from failing due to a missing database.

#### 5. PORT VISIBILITY
Open the application in your browser. Make both frontend and backend visibility public. 
You should see the seeded users on the login page
![seeded_data](_docs/assets/week-5/seeded_data_and_user.png)


#### 6. Set Up Local DynamoDB

Navigate to:

```sh
backend-flask/bin/ddb
```

Run:

```sh
./schema-load
./seed
```
After running the seed script, a dumpl load of json data should show on the screen.

This:
- Creates DynamoDB tables locally
- Seeds initial data (e.g., user conversations/messages)
- Successful execution confirms that local DynamoDB integration is working.

Proceed to the frontend URL, log in, navigate to messages and confirm there is a seeded message conversation.
![seeded_conversation](_docs/assets/week-5/seeded_conversation.png)


#### 7. CREATE NEW MESSAGE


#### 7. Transition to Production Setup
To send a message to a new user, hit /messages/new/<username> to initiate chat with a new user.
![create_new_message](_docs/assets/week-5/create_new_message.png)

### Production Setup, Seeding, and DynamoDB Integration
1. Switch to Production DynamoDB

Bring down the current Docker environment:

docker compose down

Open docker-compose.yaml and comment out:

AWS_ENDPOINT_URL

Bring the environment back up:

docker compose up

⚠️ Note:
You are still using local PostgreSQL.
Only DynamoDB is now connected to production (AWS).

2. Create DynamoDB Table in AWS

Navigate to:

backend-flask/bin/ddb

Make the script executable and run:

chmod +x schema-load
./schema-load prod
This will:
Authenticate with AWS
Create the DynamoDB table in your AWS account
3. Seed Production DynamoDB

Run:

./seed prod
This populates the table with initial data (e.g., messages/conversations).
4. Enable DynamoDB Streams
In the AWS Console:
Go to DynamoDB
Select your table

Navigate to:

Exports and streams → DynamoDB stream details

Enable streams and choose:

New image
This allows capturing newly written items for downstream processing.
5. Configure VPC Endpoint for DynamoDB

For DynamoDB to work with Lambda inside a VPC:

Go to:

VPC → PrivateLink and Lattice → Endpoints
Create a new endpoint:
Type: AWS services
Service: DynamoDB
Endpoint type: Gateway
Select:
Your VPC
Appropriate route tables
Allow full access
Create the endpoint
6. Create Lambda Function
Navigate to AWS Lambda (AWS Lambda)
Create a function:
Author from scratch
Runtime: Python 3.10
Architecture: Any
Use default execution role (temporary)
Under Advanced settings:
Attach the function to your VPC
Select:
Subnets
Security group
7. Deploy Lambda Code

Locate:

aws/lambda/cruddur-messaging-stream.py
Copy the contents into the Lambda inline editor
Click Deploy
8. Configure IAM Permissions

Go to:

Lambda → Configuration → Execution Role
Click the attached role and:
Create Inline Policy
Select JSON

Paste:

aws/policy/cruddur-message-stream-policy.json
Save with a meaningful name
Attach AWS managed policy:
AWSLambdaInvocation-DynamoDB
9. Add DynamoDB Trigger
In Lambda:
Go to Triggers
Add trigger:
Source: DynamoDB
Select your table
Batch size: 1 (for now)
This connects DynamoDB Streams to Lambda.
10. Test the Flow
Go to the frontend app
Send a message
Then verify logs in Amazon CloudWatch:
Navigate to CloudWatch Logs
Check your Lambda log group
Confirm the stream is triggering the Lambda function

./schema-seed prod
./seed
This will:
Authenticate with AWS
Create DynamoDB tables in your AWS account
Seed production data

in week 4, some users signed up on the cruddur app, navigate to [seed.sql](backend-flask/db/seed.sql) and simply replace the values with corresponding details from cognito to be seeded in the DB. Run this [image-build](.devcontainer/image_build.sh) script to build both the frontend and backend image. Check the compose file to confirm `AWS_ENDPOINT_URL` is set, this is needed for local DYNAMODB connection. Before bringing up the docker compose file, split the terminal screen, then navigate to [db-utility-scripts](backend-flask/bin/db). Ensure the environment variables for cognito are added in .env, CONNECTION_URL is set, and AWS_SECRETS. Bring up the docker compose file on the first screen, on the second screen, execute the `./load` script, ensure it executable, this creates the `cruddur` database so that the backend doesn't exit. This should be succesful. Proceed to make the ports public, for both frontend and backend, there should show seeded data on the login page. Navigate to [DDB-SCRIPTS](backend-flask/bin/ddb), execute the `schema-load` and the `seed` scripts. This should create a user conversation in the Messages. This confirms everything works locally and we can proceed to production, bring down the compose file. Comment out the `AWS_ENDPOINT_URL`, then bring up the compose file. Navigate to DDB-SCRIPTS, then run `./schema-seed prod` this authenticates with AWS and creates a DYNAMO DB TABLE. Run the seed script. 

⚡ Git & Commit Workflow Fix

Fixed Commitizen configuration:

rm -f ~/.czrc
cat > ~/.czrc <<'EOF'
{"path": "cz-gitmoji-changelog"}
EOF
🔄 DynamoDB Streams & Lambda
1. Enable Streams
Set DynamoDB Stream to:
NEW_IMAGE
2. Create Lambda Function

Using AWS Lambda:

Runtime: Python
Permissions: AWSLambdaInvocation-DynamoDB
3. Configure Trigger
Connect DynamoDB Stream to Lambda
Settings:
Batch size: 1
Trigger: Enabled
🧪 Development Workflow Improvements
Codespaces Automation

Added startup steps:

cd backend
pip install -r requirements.txt
Reusable Setup Enhancements
Automated AWS credential injection
Standardized environment setup
Reduced onboarding friction
✅ Summary of Achievements
Integrated DynamoDB with structured scripts
Implemented access patterns for scalability
Added Cognito user management automation
Enabled DynamoDB Streams + Lambda triggers
Improved developer workflow with Codespaces
Refactored backend for better maintainability
🚀 Next Steps (Optional Ideas)
Add logging/monitoring (CloudWatch)
Implement retries & error handling in Lambda
Add API layer for DynamoDB access
Introduce CI/CD pipeline for deployments





An error occurred when creating the trigger: Cannot access stream arn:aws:dynamodb:us-east-1:193654356005:table/cruddur-messages/stream/2026-03-24T17:01:03.860. Please ensure the role can perform the GetRecords, GetShardIterator, DescribeStream, and ListStreams Actions on your stream in IAM.