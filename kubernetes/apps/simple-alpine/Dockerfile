FROM alpine:latest

RUN apk update
RUN apk add --no-cache curl tini

CMD ["sleep", "infinity"]
ENTRYPOINT ["tini", "--"]
