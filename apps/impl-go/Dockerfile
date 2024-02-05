FROM golang:1.21-bookworm AS build

WORKDIR /app

COPY main.go .

RUN go build -o sample-go main.go

FROM ubuntu:jammy

RUN apt-get update
RUN apt-get -y install ca-certificates tini

COPY --from=build /app/sample-go /usr/local/bin/sample-go

CMD ["sleep", "infinity"]
ENTRYPOINT ["tini", "--"]
