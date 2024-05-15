FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get upgrade -y \
        gawk \
        coreutils \
        grep    \
        sed \
        nginx \
        openjdk-17-jdk \
        maven && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /alm

COPY . .

RUN cp /alm/.scripts/update_conf.sh /bin/update_conf && cp /alm/.scripts/install_nginx.sh /bin/install_nginx && cp /alm/.scripts/remove_nginx.sh /bin/remove_nginx
RUN chmod +x /bin/update_conf /bin/install_nginx /bin/remove_nginx

EXPOSE 80

# The command to start Nginx when the container starts
CMD ["nginx", "-g", "daemon off;"]
