FROM node:20

RUN apt-get update
RUN apt-get -y install ca-certificates tini

WORKDIR /app

COPY app.js /app/app.js
COPY package.json /app/package.json
COPY package-lock.json /app/package-lock.json

WORKDIR /app

RUN npm ci

CMD ["sleep", "infinity"]
ENTRYPOINT ["tini", "--"]
