FROM golang:latest AS build

WORKDIR /app

COPY main.go .

RUN go build -o sample-go main.go

FROM ubuntu:latest

RUN apt-get update
RUN apt-get -y install tini

COPY --from=build /app/sample-go /usr/local/bin/sample-go

CMD ["sleep", "infinity"]
ENTRYPOINT ["tini", "--"]
