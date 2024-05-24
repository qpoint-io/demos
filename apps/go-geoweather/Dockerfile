# Use the official Golang image to create a build artifact.
FROM golang:1.22 as builder

# Set the working directory inside the container.
WORKDIR /app

# Copy the source code into the container.
COPY . .

# Build the Go app.
RUN go mod tidy
RUN GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o main

# Use a minimal image for the final container.
FROM alpine:latest

# Get latest public CA's
RUN apk --no-cache add ca-certificates

# Set the working directory inside the container.
WORKDIR /app

# Copy the binary from the builder stage.
COPY --from=builder /app/main .

# Make port 80 available to the world outside this container.
EXPOSE 80

# Run the binary program.
CMD ["./main"]
