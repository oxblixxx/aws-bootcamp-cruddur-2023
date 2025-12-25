#!/bin/bash
set -e  # exit on error

# frontend setup
cd /workspaces/aws-bootcamp-cruddur-2023/frontend-react-js
npm install
npm install --save @opentelemetry/api @opentelemetry/sdk-trace-web @opentelemetry/exporter-trace-otlp-http \
@opentelemetry/context-zone @opentelemetry/instrumentation @opentelemetry/instrumentation-xml-http-request \
@opentelemetry/instrumentation-fetch aws-amplify

# copy env file if not exists
cd /workspaces/aws-bootcamp-cruddur-2023
cp -n .env.example .env || true
sed -i "s|^AWS_DEFAULT_REGION=.*|AWS_DEFAULT_REGION=us-east-1|" .env || echo AWS_DEFAULT_REGION=us-east-1 >> .env

# docker compose
sudo docker compose up -d
