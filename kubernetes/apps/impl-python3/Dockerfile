FROM python:3.9-slim

RUN apt-get update
RUN apt-get -y install ca-certificates tini

WORKDIR /app

COPY app.py /app/app.py

CMD ["sleep", "infinity"]
ENTRYPOINT ["tini", "--"]
