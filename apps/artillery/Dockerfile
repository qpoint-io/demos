# Use the official Node.js runtime as a base image
FROM node:14-slim

# Update the system and install necessary tools
RUN apt-get update

# Install Artillery globally using npm
RUN npm install -g artillery

# Copy artillery config into the image
COPY ./artillery-config.yaml /artillery-config.yaml

# Use artillery with the custom config
CMD ["artillery", "run", "/artillery-config.yaml"]
