FROM node:20-alpine

WORKDIR /opt/mywebapp

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 8000

CMD ["npm", "start"]