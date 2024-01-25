FROM ruby:latest

RUN apt-get update
RUN apt-get -y install ca-certificates tini

WORKDIR /app

COPY app.rb /app/app.rb

CMD ["sleep", "infinity"]
ENTRYPOINT ["tini", "--"]
