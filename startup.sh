#!/bin/bash
sudo apt update
sudo apt install -y curl gnupg2 lsb-release postgresql-client libpq-dev nodejs npm
chmod +x .devcontainer/setup.sh

cd /workspaces/aws-bootcamp-cruddur-2023/frontend-react-js
npm install
npm install --save @opentelemetry/api @opentelemetry/sdk-trace-web @opentelemetry/exporter-trace-otlp-http @opentelemetry/context-zone @opentelemetry/instrumentation @opentelemetry/instrumentation-xml-http-request @opentelemetry/instrumentation-fetch aws-amplify

cd /workspaces/aws-bootcamp-cruddur-2023
cp -n .env.example .env
sed -i "s|^AWS_DEFAULT_REGION=.*|AWS_DEFAULT_REGION=us-east-1|" .env || echo AWS_DEFAULT_REGION=us-east-1 >> .env

sudo docker compose up -d
