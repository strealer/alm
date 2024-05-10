# Specify Ubuntu as the base image
FROM ubuntu:latest

# Install Nginx
RUN apt-get update -y && apt-get upgrade -y \
        gawk \
        coreutils \
        grep    \
        sed \
        nginx \
        openjdk-17-jdk \
        maven

WORKDIR /alm

COPY . .

RUN cp /alm/.scripts/update_conf.sh /bin/update_conf && cp /alm/.scripts/install_nginx.sh /bin/install_nginx && cp /alm/.scripts/remove_nginx.sh /bin/remove_nginx
RUN chmod +x /bin/update_conf /bin/install_nginx /bin/remove_nginx

# Expose the default Nginx port
EXPOSE 80

# Define the command to start Nginx when the container starts
CMD ["nginx", "-g", "daemon off;"]
