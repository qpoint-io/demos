# Use an official PHP runtime as a parent image
FROM php:7.4-apache

# Get latest CA's
ARG TOKEN
RUN apt-get update && \
    apt-get install -y curl ca-certificates && \
    curl -s https://api.qpoint.io/deploy/certificate -H "Authorization: Bearer $TOKEN" > /usr/local/share/ca-certificates/qpoint-ca.crt && \
    update-ca-certificates && \
    rm -rf /var/lib/apt/lists/*


# Copy the current directory contents into the container at /var/www/html
COPY . /var/www/html/

# Install necessary extensions
RUN docker-php-ext-install json

# Set the ServerName directive globally to suppress the warning
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Make port 80 available to the world outside this container
EXPOSE 80

