# Stage 1: Build the dependencies and cache them
FROM ubuntu:22.04 AS base

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        gawk \
        coreutils \
        grep \
        sed \
        nginx \
        openjdk-17-jdk-headless \
        maven && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /alm

# Stage 2: Copy the cached layers and build the application
FROM base AS builder

COPY . .

RUN cp /alm/.scripts/update_conf.sh /bin/update_conf && cp /alm/.scripts/install_nginx.sh /bin/install_nginx && cp /alm/.scripts/remove_nginx.sh /bin/remove_nginx
RUN chmod +x /bin/update_conf /bin/install_nginx /bin/remove_nginx

RUN mvn clean
RUN mvn package
RUN mvn install

# Stage 3: Create the final image
FROM ubuntu:22.04

COPY --from=base /usr/local /usr/local
COPY --from=builder /alm /alm
COPY --from=builder /bin/update_conf /bin/update_conf
COPY --from=builder /bin/install_nginx /bin/install_nginx
COPY --from=builder /bin/remove_nginx /bin/remove_nginx

WORKDIR /alm

EXPOSE 80

# The command to start Nginx when the container starts
CMD ["nginx", "-g", "daemon off;"]
