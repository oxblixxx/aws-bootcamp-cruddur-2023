# Week 2 — Distributed Tracing

## Class Summary



## Instrument our backend flask application to use Open Telemetry (OTEL) with Honeycomb as the provider

 Signup an account on Honeycomb, [click here](https://ui.honeycomb.io/signup).
 
 Create an environment with a preferred name. Copy the API Keys.
 
 Return to your code editor. In requirements.txt paste in this packages required for OTEL. Run ** Pip install -r requirements.txt ** to install the packages.
 
 ```
pip install opentelemetry-api
pip install opentelemetry-sdk
pip install opentelemetry-exporter-otlp-proto-http
pip install opentelemetry-instrumentation-flask
pip install opentelemetry-instrumentation-requests
 
 ```
 Then cd into backend-flask/app.py directory. Paste the below code to initialize a tracer and flask instrumentation to send data to Honeycomb
 
 ```py
 # app.py

 # Honeycomb-------
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Initialize tracing and an exporter that can send data to Honeycomb
provider = TracerProvider()
processor = BatchSpanProcessor(OTLPSpanExporter())
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)
tracer = trace.get_tracer(__name__)

# Initialize automatic instrumentation with Flask
app = flask.Flask(__name__)
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()

 ```
 
 Update the Docker-compose.yml file 
 
 ```yaml
 environment:
      FRONTEND_URL: "https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
      BACKEND_URL: "https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
      OTEL_SERVICE_NAME: 'backend-flask'
      OTEL_EXPORTER_OTLP_ENDPOINT: "https://api.honeycomb.io"
      OTEL_EXPORTER_OTLP_HEADERS: "x-honeycomb-team=${HONEYCOMB_API_KEY}"
 ```
 
FROM THE HONEYCOMB UI, FETCH THE API AND EXPORT IT

## Instrument AWS X-Ray into backend flask application
Implementing AWS XRAY
add to requirements.txt
 
```
aws-xray-sdk
```

to install the dependencies then run

```
pip install -r requirements.txt
```

cd into backend-flask/app.py, add the below code
```
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.ext.flask.middleware import XRayMiddleware

xray_url = os.getenv("AWS_XRAY_URL")
xray_recorder.configure(service='Cruddur', dynamic_naming=xray_url)
XRayMiddleware(app, xray_recorder)
```

then put in aws/json/xray.json the below

```
{
  "SamplingRule": {
      "RuleName": "Cruddur",
      "ResourceARN": "*",
      "Priority": 9000,
      "FixedRate": 0.1,
      "ReservoirSize": 5,
      "ServiceName": "backend-flask",
      "ServiceType": "*",
      "Host": "*",
      "HTTPMethod": "*",
      "URLPath": "*",
      "Version": 1
  }
}
```

in your terminal paste the below code, show return a json if succesful

```
FLASK_ADDRESS="https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
aws xray create-group \
   --group-name "Cruddur" \
   --filter-expression "service(\"backend-flask\")"
```
```
aws xray create-sampling-rule --cli-input-json file://aws/json/xray.json
```

Install and start the xray demon 

```
 wget https://s3.us-east-2.amazonaws.com/aws-xray-assets.us-east-2/xray-daemon/aws-xray-daemon-3.x.deb
 sudo dpkg -i **.deb
```

Just incase you come against this authentication error in Xray daemon logs, create a .env with your credentials in the directory your docker-compose is located 

```
NoCredentialProviders: no valid providers in chain. Deprecated. For verbose messaging see aws.Config.CredentialsChainVerboseErrors
```



## Cloudwatch Logs
update ~/backend-flask/requirements.txt; add

```
watchtower
```

cd into app.py; paste the below

```
# Cloudwatch logs
import watchtower
import logging
from time import strftime

# Configuring Logger to Use CloudWatch
LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(logging.DEBUG)
console_handler = logging.StreamHandler()
cw_handler = watchtower.CloudWatchLogHandler(log_group='cruddur')
LOGGER.addHandler(console_handler)
LOGGER.addHandler(cw_handler)
LOGGER.info("HomeActivities")
```

```
@app.after_request
def after_request(response):
    timestamp = strftime('[%Y-%b-%d %H:%M]')
    LOGGER.error('%s %s %s %s %s %s', timestamp, request.remote_addr, request.method, request.scheme, request.full_path, response.status)
    return response
```

then cd into your docker-compose file; add to env variables to access AWS

```
  AWS_DEFAULT_REGION: "${AWS_DEFAULT_REGION}"
  AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
  AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
```
cd into ~/backend-flask/services/home_activities.py; add the below

```
Logger.info("HomeActivities")
```

in app.py, update the API Endpoint as this

```
  data = HomeActivities.run(Logger=LOGGER)
```

Login into your AWS Console, search for CLOUDWATCH LOGS, check Log groups for home activities Log streams



## Interagate ROLLBAR FOR LOGGING
sign up for [a Rollbar account](https://rollbar.com)

create a project "Cruddur" and create an integration for flask, copy the access token

cd into ~/backend-flask/requirements.txt; add Rollbar python dependecies and run pip install -r requrements.txt

```
blinker
rollbar
```

create a .env file, add ROLLBAR ACCESS TOKEN

```
 ROLLBAR_ACCESS_TOKEN=""
```
Add to docker-compose for Rollbar

```
ROLLBAR_ACCESS_TOKEN: "${ROLLBAR_ACCESS_TOKEN}"
```
cd into ~/backend-flask/app.py. Update it with the below code

```
import os
import rollbar
import rollbar.contrib.flask
from flask import got_request_exception
```

```
rollbar_access_token = os.getenv('ROLLBAR_ACCESS_TOKEN')
@app.before_first_request
def init_rollbar():
    """init rollbar module"""
    rollbar.init(
        # access token
        rollbar_access_token,
        # environment name
        'production',
        # server root directory, makes tracebacks prettier
        root=os.path.dirname(os.path.realpath(__file__)),
        # flask already sets up logging
        allow_logging_basic_config=False)

    # send exceptions from `app` to rollbar, using flask's signal system.
    got_request_exception.connect(rollbar.contrib.flask.report_exception, app)
```
Here is an API endpoint to test for rollbar, should be in app.py as well


```
@app.route('/rollbar/test')
def rollbar_test():
    rollbar.report_message('Hello World!', 'warning')
    return "Hello World!"
```

    
    






  
