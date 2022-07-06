FROM node

# Create app directory
WORKDIR /usr/src/app

COPY package.json .

# RUN npm install
RUN npm install

# Move all files
COPY . /usr/src/app/

# Build project
RUN npm run build; exit 0

# Start Server
# CMD [ "node", "build/main.js" ]
CMD ["npx", "http-server", "dist"]