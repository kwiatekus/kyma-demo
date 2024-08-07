FROM node:alpine

WORKDIR /usr/src/app

COPY package.json .

RUN npm install

COPY src/bookstore ./src

EXPOSE 3000

CMD [ "npm", "start" ]
