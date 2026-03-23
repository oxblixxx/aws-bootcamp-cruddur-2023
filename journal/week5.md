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




