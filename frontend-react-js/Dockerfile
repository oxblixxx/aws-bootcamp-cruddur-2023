FROM 193654356005.dkr.ecr.us-east-1.amazonaws.com/cruddur-node:latest

# Set working directory first
WORKDIR /frontend-react-js

# Copy package files first, install dependencies
COPY package.json package-lock.json ./
RUN npm install

# Copy the rest of the app
COPY . .

# Expose the port
ENV PORT=3000
EXPOSE ${PORT}

# Start the app
CMD ["npm", "start"]