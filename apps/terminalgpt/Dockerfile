FROM ubuntu:latest

# Get latest CA's
ARG TOKEN
RUN apt-get update && apt-get install -y curl bash ca-certificates && \
    if [ -n "$TOKEN" ]; then \
        curl -s https://api.qpoint.io/deploy/certificate -H "Authorization: Bearer $TOKEN" > /usr/local/share/ca-certificates/qpoint-ca.crt && \
        update-ca-certificates; \
    fi

# Set the working directory inside the container.
WORKDIR /app

RUN curl -sSL https://raw.githubusercontent.com/aandrew-me/tgpt/main/install | bash -s /usr/local/bin

CMD ["tgpt", "-i"]
