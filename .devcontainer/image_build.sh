#!/bin/bash
cd frontend-react-js
docker image build -t cruddur-frontend:v1 .
cd ../backend-flask
docker image build -t cruddur-backend:v1 .
