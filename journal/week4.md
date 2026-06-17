# Week 4 — Postgres and RDS

## Creating a postgres database usin the CLI

In the prior week, I included Postgresql database image in our docker-compose.yml and in the gitpod.yml, there is the task to install postgresql. 

configure aws credentials then open the terminal, copy and and paste the below code, stopping the database on AWS console ensentially stops it for 7days of which it starts automatically.

https://docs.aws.amazon.com/cli/latest/reference/rds/

```sql
aws rds create-db-instance \
  --db-instance-identifier cruddur-db-instance \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version  14.17 \
  --master-username oxblixxx \
  --master-user-password wearewinning \
  --allocated-storage 20 \
  --availability-zone us-east-1a \
  --backup-retention-period 0 \
  --port 5432 \
  --no-multi-az \
  --db-name cruddur \
  --storage-type gp2 \
  --publicly-accessible \
  --storage-encrypted \
  --enable-performance-insights \
  --performance-insights-retention-period 7 \
  --no-deletion-protection
```
Check the docker logs to see if postgresql is running. That's a must! Run the command below to login into the local db and the password is "password" as the name implies :)

```sql
psql -Upostgres --host localhost
```

this are commands to run while logged into the db and there is more

```sql
\x on -- expanded display when looking at data
\q -- Quit PSQL
\l -- List all databases
\c database_name -- Connect to a specific database
\dt -- List all tables in the current database
\d table_name -- Describe a specific table
\du -- List all users and their roles
\dn -- List all schemas in the current database
CREATE DATABASE database_name; -- Create a new database
DROP DATABASE database_name; -- Delete a database
CREATE TABLE table_name (column1 datatype1, column2 datatype2, ...); -- Create a new table
DROP TABLE table_name; -- Delete a table
SELECT column1, column2, ... FROM table_name WHERE condition; -- Select data from a table
INSERT INTO table_name (column1, column2, ...) VALUES (value1, value2, ...); -- Insert data into a table
UPDATE table_name SET column1 = value1, column2 = value2, ... WHERE condition; -- Update data in a table
DELETE FROM table_name WHERE condition; -- Delete data from a table
```

create a db named cruddur on the local database with
``` sql
create database cruddur;
```

A postgresql extension needs to be applied to generate random numbers for users and allocate to them, Copy and paste the code below in a folder db, then create schema.sql ::UUID implies universaally unique identifier

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```
run the schema with the command below, 

```
psql cruddur < db/schema.sql -h localhost -U postgres
```
to avoide passwword prompt, there a various ways to login but we will use the CONNECTION URL METHOD, then create an environment variable for quick access

```
psql postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}
psql postgresql://postgres:password@localhost:5432
```

create a bin directory, in the bin directory create files without an extension db-create, db-schema-load, db-drop. from anywhere on the terminal run the command 
```sh
whereis bash
```

open db-create with your favourite text editor, paste the below code. Run chmod +x db-create db-schema-load db-drop to make the files executable

```sh
#! /usr/bin/bash 
echo "drop create database"
NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
$NO_DB_CONNECTION_URL -c "CREATE database cruddur;"
```
open db-drop as well, paste the below code

```sh
#! /usr/bin/bash 
echo "drop databse"
NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
$NO_DB_CONNECTION_URL -c "DROP database cruddur;"
```

open db-load-schema as well, paste the below code, in the this file, we are update it with a condition to use production environment and development environment, also to pull the path of the schema.sql file. Meanwhile, the production envirinment needs to be set. Login to the AWS console, open the RDS dashboard, on the previously created db using the AWS CLI. Under connectivity and security copy the endpoint url.

```sh
#! /usr/bin/bash 

schema_path="$(realpath ..)/db/schema.sql"
echo $schema_path
echo "db-schema-load"

if [ "$1" == "production"]; then
    echo "using production db"
    URL=$PROD_CONNECTION_URL
else 
    echo "using in development db"
    URL=$CONNECTION_URL
fi

$CONNECTION_URL cruddur < $schema_path

```
cd into the schema directory backend-flask/bin, update the schema.sql with an editor with tables of activities and user. 

```sql
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.activities;
```
```sql
CREATE TABLE public.users (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  display_name text NOT NULL,
  handle text NOT NULL,
  email text NOT NULL,
  cognito_user_id text NOT NULL,
  created_at TIMESTAMP default current_timestamp NOT NULL
);
```
```sql
CREATE TABLE public.activities (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_uuid UUID NOT NULL,
  message text NOT NULL,
  replies_count integer DEFAULT 0,
  reposts_count integer DEFAULT 0,
  likes_count integer DEFAULT 0,
  reply_to_activity_uuid integer,
  expires_at TIMESTAMP,
  created_at TIMESTAMP default current_timestamp NOT NULL
);
```

in the current directory create a seed file then cd into backend-flask/db, create a script to run to load the seed file as well, ensure to change the file permssion as well

```sql
-- this file was manually created
INSERT INTO public.users (display_name, handle, cognito_user_id)
VALUES
  ('Andrew Brown', 'andrewbrown' ,'MOCK'),
  ('Andrew Bayko', 'bayko' ,'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'andrewbrown' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )
```

```sh
#! /usr/bin/bash 

seed_path="$(realpath ..)/db/seed.sql"

echo $seed_path

echo "db-seed"

if [ "$1" == "production" ]; then
    echo "using production db"
    URL=$PROD_CONNECTION_URL
else 
    echo "using in development db"
    URL=$LOCAL_CONNECTION_URL
fi

$URL cruddur < $seed_path
```

You can as well run a a script to compile the db-load, db-seed in a script as well, cd into backend-flask/bin create a file db-load and put in the below command in there

```sh
#! /usr/bin/bash

-e # stop if it fails at any point

#echo "==== db-setup"

bin_path="$(realpath ..)/bin"

source "$bin_path/db-drop"
source "$bin_path/db-create"
source "$bin_path/db-schema-load"
source "$bin_path/db-seed"
```

to view actice sessions connected to db, create a file in the backend-flask/bin and open a db-session
```sh
#! /usr/bin/bash

if [ "$1" == "prod" ]; then
    echo "using production db"
    URL=$PROD_CONNECTION_URL
else 
    echo "using in development db"
    URL=$LOCAL_CONNECTION_URL
fi


NO_URL=$(sed 's/\/cruddur//g' <<<"$URL")
$NO_URL -c "select pid as process_id, \
       usename as user,  \
       datname as db, \
       client_addr, \
       application_name as app,\
       state \
from pg_stat_activity;"
```

update requirements.txt to install for postgres client, update the docker-compose.yaml to set the env for the postgres login. Run pip install -r requirements.txt.

```yaml
  backend-flask:
    environment:
      CONNECTION_URL:  "postgresql://postgres:password@db:5432/cruddur" 
```

here is the link to the docs  [https://www.psycopg.org/psycopg3/](https://www.psycopg.org/psycopg3/)
```txt
psycopg[binary]
psycopg[pool]
```

for the Db object and connection opem backend-flask/lib/db.py

```py
from psycopg_pool import ConnectionPool
import os

def query_wrap_object(template):
  sql = f"""
  (SELECT COALESCE(row_to_json(object_row),'{{}}'::json) FROM (
  {template}
  ) object_row);
  """
  return sql

def query_wrap_array(template):
  sql = f"""
  (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
  {template}
  ) array_row);
  """
  return sql

connection_url = os.getenv("CONNECTION_URL")
pool = ConnectionPool(connection_url)
```

update services/home_activities.py with the api call

```py
sql = query_wrap_array("""
      SELECT
        activities.uuid,
        users.display_name,
        users.handle,
        activities.message,
        activities.replies_count,
        activities.reposts_count,
        activities.likes_count,
        activities.reply_to_activity_uuid,
        activities.expires_at,
        activities.created_at
      FROM public.activities
      LEFT JOIN public.users ON users.uuid = activities.user_uuid
      ORDER BY activities.created_at DESC
    """)
    print("SQL--------------")
    print(sql)
    print("SQL--------------")
    with pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(sql)
        # this will return a tuple
        # the first field being the data
        json = cur.fetchone()
    print("-1----")
    print(json[0])
    return json[0]
    return results
```

# CONNECT TO DB
to connect to db we need to allow inbound rule from gitpod IP address. Run the command 

```sh
echo GITPOD_IP=$(curl ifconfig.me)
```
to automatically update the gitpod IP on relaunch, login to your console, fetch the security group ID and security rule group ID attached to the RDS. Then set the env variables. Description should be set as GITPOD

```sh
export DB_SG_ID="sg-08895646d8830b0eb"
gp env DB_SG_ID="sg-08895646d8830b0eb"
```

```sh
aws ec2 authorize-security-group-ingress \
  --group-id $DB_SG_ID \
  --ip-permissions IpProtocol=tcp,FromPort=5432,ToPort=5432,IpRanges="[{CidrIp=${GITPOD_IP}/32,Description=\"GITPOD\"}]"
```

on relaunch, to set gitpod to automatticaly update the sg, add the below code
```sh
    command: |
      export GITPOD_IP=$(curl ifconfig.me)
      source "$THEIA_WORKSPACE_ROOT/backend-flask/rds-update-sg-rule"
```

Also set the PROD env `export PROD_CONNECTION_URL="postgresql://oxblixxx:wearewinning@cruddur-db-instance.c2vcui044zod.us-east-1.rds.amazonaws.com/cruddur"`
---
# Create a Lamda function for Cognito Confirmation 
login to aws console, create a lamda function with python version 3.8

here is the code to deploy
```py
import json
import psycopg2
import os

def lambda_handler(event, context):
    user = event['request']['userAttributes']
    print('userAttributes')
    print(user)

    user_display_name  = user['name']
    user_email         = user['email']
    user_handle        = user['preferred_username']
    user_cognito_id    = user['sub']
    try:
      sql = f"""
         INSERT INTO public.users (
          display_name, 
          email,
          handle, 
          cognito_user_id
          ) 
        VALUES(
        '{user_display_name}',
        '{user_email}',
        '{user_handle}',
        '{user_cognito_id}'
        )
      """
      print('SQL Statement ----')
      print(sql)
      conn = psycopg2.connect(os.getenv('PROD_CONNECTION_URL'))
      cur = conn.cursor()
      cur.execute(sql)
      conn.commit() 

    except (Exception, psycopg2.DatabaseError) as error:
      print(error)
    finally:
      if conn is not None:
          cur.close()
          conn.close()
          print('Database connection closed.')
    return event
```
add environment variable for your prod db in lamda

then add the vpc where the database is located, attach at least 2 subnets. Incase of this error "The provided execution role does not have permissions to call CreateNetworkInterface on EC2" while creating resolve it by adding a policy, click the rolename 

```
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeInstances",
        "ec2:AttachNetworkInterface"

```
ensure to attach the policy otherwise you get an error while attaching the VPC.

then add a new layer, specify ARN. We are using a library names pyscopg -- here is a link to the documentation ![psycopg](https://github.com/jetbridge/psycopg2-lambda-layer). Choose the one specific to your location and version. 

proceed to cognito to apply the lamda triggers under user pool properties, choose post confirmation, the previously created lamda, then create lamda.

check Cloudwatch from the lamda page incase of any errors.

login to the production database to see if the signup information is succesfully added, run
```sql
select * from users;
```

# Implement activity token

implementing the token for the api endpoints.

cd into backend-flask, mkdir db/sql/activities. create home.sql, object.sql and create.sql files.

## Create.sql
```sql
INSERT INTO public.activities (
  user_uuid,
  message,
  expires_at
)
VALUES (
  (SELECT uuid 
    FROM public.users 
    WHERE users.handle = %(handle)s
    LIMIT 1
  ),
  %(message)s,
  %(expires_at)s
) RETURNING uuid;
```
## object.sql

```sql
SELECT
  activities.uuid,
  users.display_name,
  users.handle,
  activities.message,
  activities.created_at,
  activities.expires_at
FROM public.activities
INNER JOIN public.users ON users.uuid = activities.user_uuid 
WHERE 
  activities.uuid = %(uuid)s
```

## home.sql

```sql
SELECT
  activities.uuid,
  users.display_name,
  users.handle,
  activities.message,
  activities.replies_count,
  activities.reposts_count,
  activities.likes_count,
  activities.reply_to_activity_uuid,
  activities.expires_at,
  activities.created_at
FROM public.activities
LEFT JOIN public.users ON users.uuid = activities.user_uuid
ORDER BY activities.created_at DESC
```

then cd into ..backend-flask/iib and update db.py

```py
from psycopg_pool import ConnectionPool
import os
import re
import sys
from flask import current_app as app

class Db:
  def __init__(self):
    self.init_pool()

  def template(self,*args):
    pathing = list((app.root_path,'db','sql',) + args)
    pathing[-1] = pathing[-1] + ".sql"

    template_path = os.path.join(*pathing)

    green = '\033[92m'
    no_color = '\033[0m'
    print("\n")
    print(f'{green} Load SQL Template: {template_path} {no_color}')

    with open(template_path, 'r') as f:
      template_content = f.read()
    return template_content

  def init_pool(self):
    connection_url = os.getenv("CONNECTION_URL")
    self.pool = ConnectionPool(connection_url)
  # we want to commit data such as an insert
  # be sure to check for RETURNING in all uppercases
  def print_params(self,params):
    blue = '\033[94m'
    no_color = '\033[0m'
    print(f'{blue} SQL Params:{no_color}')
    for key, value in params.items():
      print(key, ":", value)

  def print_sql(self,title,sql):
    cyan = '\033[96m'
    no_color = '\033[0m'
    print(f'{cyan} SQL STATEMENT-[{title}]------{no_color}')
    print(sql)
  def query_commit(self,sql,params={}):
    self.print_sql('commit with returning',sql)

    pattern = r"\bRETURNING\b"
    is_returning_id = re.search(pattern, sql)

    try:
      with self.pool.connection() as conn:
        cur =  conn.cursor()
        cur.execute(sql,params)
        if is_returning_id:
          returning_id = cur.fetchone()[0]
        conn.commit() 
        if is_returning_id:
          return returning_id
    except Exception as err:
      self.print_sql_err(err)
  # when we want to return a json object
  def query_array_json(self,sql,params={}):
    self.print_sql('array',sql)

    wrapped_sql = self.query_wrap_array(sql)
    with self.pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(wrapped_sql,params)
        json = cur.fetchone()
        return json[0]
  # When we want to return an array of json objects
  def query_object_json(self,sql,params={}):

    self.print_sql('json',sql)
    self.print_params(params)
    wrapped_sql = self.query_wrap_object(sql)

    with self.pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(wrapped_sql,params)
        json = cur.fetchone()
        if json == None:
          "{}"
        else:
          return json[0]
  def query_wrap_object(self,template):
    sql = f"""
    (SELECT COALESCE(row_to_json(object_row),'{{}}'::json) FROM (
    {template}
    ) object_row);
    """
    return sql
  def query_wrap_array(self,template):
    sql = f"""
    (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
    {template}
    ) array_row);
    """
    return sql
  def print_sql_err(self,err):
    # get details about the exception
    err_type, err_obj, traceback = sys.exc_info()

    # get the line number when exception occured
    line_num = traceback.tb_lineno

    # print the connect() error
    print ("\npsycopg ERROR:", err, "on line number:", line_num)
    print ("psycopg traceback:", traceback, "-- type:", err_type)

    # print the pgcode and pgerror exceptions
    print ("pgerror:", err.pgerror)
    print ("pgcode:", err.pgcode, "\n")

db = Db()
```

update create_activity.py and home_activies.py as well in backend-flask/services directory

## create_activity.py
```py
from datetime import datetime, timedelta, timezone

from lib.db import db

class CreateActivity:
  def run(message, user_handle, ttl):
    model = {
      'errors': None,
      'data': None
    }

    now = datetime.now(timezone.utc).astimezone()

    if (ttl == '30-days'):
      ttl_offset = timedelta(days=30) 
    elif (ttl == '7-days'):
      ttl_offset = timedelta(days=7) 
    elif (ttl == '3-days'):
      ttl_offset = timedelta(days=3) 
    elif (ttl == '1-day'):
      ttl_offset = timedelta(days=1) 
    elif (ttl == '12-hours'):
      ttl_offset = timedelta(hours=12) 
    elif (ttl == '3-hours'):
      ttl_offset = timedelta(hours=3) 
    elif (ttl == '1-hour'):
      ttl_offset = timedelta(hours=1) 
    else:
      model['errors'] = ['ttl_blank']

    if user_handle == None or len(user_handle) < 1:
      model['errors'] = ['user_handle_blank']

    if message == None or len(message) < 1:
      model['errors'] = ['message_blank'] 
    elif len(message) > 280:
      model['errors'] = ['message_exceed_max_chars'] 

    if model['errors']:
      model['data'] = {
        'handle':  user_handle,
        'message': message
      }   
    else:
      expires_at = (now + ttl_offset)
      uuid = CreateActivity.create_activity(user_handle,message,expires_at)

      object_json = CreateActivity.query_object_activity(uuid)
      model['data'] = object_json
    return model

  def create_activity(handle, message, expires_at):
    sql = db.template('activities','create')
    uuid = db.query_commit(sql,{
      'handle': handle,
      'message': message,
      'expires_at': expires_at
    })
    return uuid
  def query_object_activity(uuid):
    sql = db.template('activities','object')
    return db.query_object_json(sql,{
      'uuid': uuid
    })
```

## home_activities.py

```py
from datetime import datetime, timedelta, timezone
from opentelemetry import trace

from lib.db import db

#tracer = trace.get_tracer("home.activities")

class HomeActivities:
  def run(cognito_user_id=None):
    #logger.info("HomeActivities")
    #with tracer.start_as_current_span("home-activites-mock-data"):
    #  span = trace.get_current_span()
    #  now = datetime.now(timezone.utc).astimezone()
    #  span.set_attribute("app.now", now.isoformat())
    sql = db.template('activities','home')
    results = db.query_array_json(sql)
    return results
```
## I got this error of "error connecting in 'pool-1': connection failed: Connection refused Is the server running on that host and accepting TCP/IP connections" then I checked on this stackoverflow [](https://stackoverflow.com/questions/37307346/is-the-server-running-on-host-localhost-1-and-accepting-tcp-ip-connections). I reinstalled postgresql and ran the command "sudo service postgresql start" which then started postgresql, proceeded to add the command to my gitpod.yml

