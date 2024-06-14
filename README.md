# alm
Autonomous Local Manager package


# ALM Project

## Introduction
This is the ALM project, a comprehensive solution for managing local proxy.

## Prerequisites
Before you begin, ensure you have met the following requirements:
- Java JDK 17 or higher installed
- Apache Maven 3.6.0 or higher installed

## Setup
Clone this repository to your local machine using:
```bash
git clone git@github.com:strealer/alm.git
```
Navigate to the cloned directory before proceeding with the build instructions.

Building the Project
To build the ALM project, follow these steps:

Clean the project to remove any previous build artifacts:

```bash
mvn clean
```
Compile the project and package it into a JAR file:

```bash
mvn package
```
Install the package into the local repository, which can then be used as a dependency in other projects locally:

```bash
mvn install
```
Running the Application
After building the project, you can run the application using the following command:

```bash
java -jar target/alm-1.0-SNAPSHOT.jar
```
Make sure to replace alm-1.0-SNAPSHOT.jar with the actual name of the generated snapshot JAR file in the target directory.


# Docker - ARM64

### Clone the repo & cd to it
```bash
git clone https://github.com/strealer/alm.git && cd alm
```

### Running the Image
```bash
docker-compose up alm_arm64 -d
```
This command starts a container named "alm_arm64" based on the "strealer/alm-app:arm64-latest" image, mapping port 8080 on the host to port 80 in the container. The container runs in detached mode (`-d`).

### Running Update, Install & Remove Scripts
- To update configuration:
  ```bash
  docker exec -it alm_arm64 update_conf
  ```
- To install Nginx:
  ```bash
  docker exec -it alm_arm64 install_nginx
  ```
- To remove Nginx:
  ```bash
  docker exec -it alm_arm64 remove_nginx
  ```


### Running Java Program
- To run the Java program:
 ```bash
  docker exec -it alm_arm64 java -jar target/strealer-cache-manager-1.0-SNAPSHOT.jar
  ```

# Docker - AMD64

### Clone the repo & cd to it
```bash
git clone https://github.com/strealer/alm.git && cd alm
```

### Running the Image
```bash
docker-compose up alm_amd64 -d
```
This command starts a container named "alm_amd64" based on the "strealer/alm-app:amd64-latest" image, mapping port 8080 on the host to port 80 in the container. The container runs in detached mode (`-d`).

### Running Update, Install & Remove Scripts
- To update configuration:
  ```bash
  docker exec -it alm_arm64 update_conf --backend-host "example.com" --device-id "12345" --remote-api-url "https://api.example.com" --remote-api-key "abcdefg123456"
  ```
- To install Nginx:
  ```bash
  docker exec -it alm_amd64 install_nginx
  ```
- To remove Nginx:
  ```bash
  docker exec -it alm_amd64 remove_nginx
  ```


### Running Java Program
- To run the Java program:
 ```bash
  docker exec -it alm_amd64 java -jar target/strealer-cache-manager-1.0-SNAPSHOT.jar
  ```


# Puppet

## Node Setup

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/suyashbhawsar/alm/main/.deployment/install_puppet_agent.sh)"
```
