#!/bin/bash
cd frontend-react-js
docker image build -t cruddur-frontend:v1 . --no-cache
cd ../backend-flask
docker image build -t cruddur-backend:v1 . --no-cache
