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
During Week 4, some users signed up on the Cruddur app. To reflect these users in the local database, follow the steps below:

#### 1. Seed Initial Users into PostgreSQL

Navigate to:

```sh
backend-flask/db/seed.sql
```

>Replace the placeholder values with the corresponding user details from Cognito.

This ensures that authenticated users are properly represented in the database.
2. Build Application Images

Run the image build script:

.devcontainer/image_build.sh
This builds both the frontend and backend Docker images.
3. Verify Environment Configuration

Open the docker-compose.yml file and confirm:

AWS_ENDPOINT_URL

is set.

This is required for connecting to local DynamoDB.
Also ensure the following are correctly set in your .env file:
Cognito environment variables
CONNECTION_URL
AWS_SECRETS
4. Initialize the Database

Before starting Docker:

Split your terminal into two panes

In the second terminal:

cd backend-flask/bin/db
chmod +x load
./load
This script creates the cruddur database.
It prevents the backend from failing due to a missing database.

In the first terminal:

docker compose up
5. Verify Local Setup
Expose both frontend and backend ports.
Open the application in your browser.
You should see the seeded users on the login page, confirming successful setup.
6. Set Up Local DynamoDB

Navigate to:

backend-flask/bin/ddb

Run:

./schema-load
./seed
This:
Creates DynamoDB tables locally
Seeds initial data (e.g., user conversations/messages)
Successful execution confirms that local DynamoDB integration is working.
7. Transition to Production Setup

Stop the local environment:

docker compose down

In docker-compose.yml, comment out:

AWS_ENDPOINT_URL
This ensures the app connects to real AWS DynamoDB instead of local.

Restart the application:

docker compose up
8. Deploy DynamoDB to AWS

Navigate again to:

backend-flask/bin/ddb

Run:

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
