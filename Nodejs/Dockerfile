# Use the official Node.js 18 image
FROM node:18

# Create the working directory
WORKDIR /app

ENV ENVIRONMENT=ECS

# Copy package.json (and optionally package-lock.json)
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy the rest of the app's code
COPY . .

# Expose the port your app runs on
EXPOSE 3000

# Run the app
CMD ["node", "app.js"]




