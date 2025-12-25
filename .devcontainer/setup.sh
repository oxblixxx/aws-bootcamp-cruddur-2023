#!/bin/bash
LOG_FILE="/tmp/cruddur-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "=== Cruddur Setup Started: $(date) ==="

echo "=== Step 1: Frontend directory check ==="
cd /workspaces/aws-bootcamp-cruddur-2023/frontend-react-js && echo "✓ Frontend dir OK" || echo "✗ Frontend dir FAILED"

echo "=== Step 2: package.json check ==="
ls -la package.json && echo "✓ package.json exists" || echo "✗ No package.json"

echo "=== Step 3: npm install base dependencies ==="
npm install && echo "✓ npm install OK" || echo "✗ npm install FAILED"

echo "=== Step 4: OpenTelemetry + Amplify install ==="
npm install --save @opentelemetry/api @opentelemetry/sdk-trace-web @opentelemetry/exporter-trace-otlp-http \
@opentelemetry/context-zone @opentelemetry/instrumentation @opentelemetry/instrumentation-xml-http-request \
@opentelemetry/instrumentation-fetch aws-amplify && echo "✓ OTel/Amplify OK" || echo "✗ OTel/Amplify FAILED"

echo "=== Step 5: Root directory + .env setup ==="
cd /workspaces/aws-bootcamp-cruddur-2023
echo "✓ Root dir OK"

echo "=== Step 6: Copy .env.example ==="
cp -n .env.example .env && echo "✓ .env copied" || echo "✗ .env.example missing - creating empty"
[ ! -f .env ] && touch .env && echo ".env created"

echo "=== Step 7: Set AWS_DEFAULT_REGION=us-east-1 ==="
sed -i "s|^AWS_DEFAULT_REGION=.*|AWS_DEFAULT_REGION=us-east-1|" .env && echo "✓ AWS region updated" || echo "AWS_DEFAULT_REGION=us-east-1" >> .env && echo "✓ AWS region appended"
echo "Current .env preview:"
grep AWS_DEFAULT_REGION .env || echo "No AWS_DEFAULT_REGION found"

echo "=== Step 8: Docker Compose status ==="
sudo docker info && echo "✓ Docker ready" || echo "✗ Docker not ready"
sudo docker compose ps && echo "✓ Docker Compose services listed" || echo "✗ Docker Compose check failed"

echo "=== Step 9: Start Docker services (non-blocking) ==="
sudo docker compose up -d && echo "✓ Docker services started" || echo "✗ Docker Compose up failed - services may still be starting"
sudo docker ps && echo "Current containers:"

echo "=== Setup Complete: $(date) ==="
echo "Check logs: tail -f $LOG_FILE"
echo "Manual verification:"
echo "  ls -la .env*"
echo "  sudo docker ps"
echo "  cat $LOG_FILE"
