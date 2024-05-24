# Use an official PHP runtime as a parent image
FROM php:7.4-apache

# Get latest public CA's
RUN apt install -y  ca-certificates

# Copy the current directory contents into the container at /var/www/html
COPY . /var/www/html/

# Install necessary extensions
RUN docker-php-ext-install json

# Set the ServerName directive globally to suppress the warning
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Make port 80 available to the world outside this container
EXPOSE 80

