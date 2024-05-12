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


## Docker Instructions

### Pulling the Image
```shell
docker pull strealer/alm-app
```

### Running the Image
```shell
docker run -d -p 8080:80 --name alm strealer/alm-app
```
This command starts a container named "alm" based on the "strealer/alm-app" image, mapping port 8080 on the host to port 80 in the container. The container runs in detached mode (`-d`).

### Running Update, Install & Remove Scripts
- To update configuration:
  ```shell
  docker exec -it alm update_conf
  ```
- To install Nginx:
  ```shell
  docker exec -it alm install_nginx
  ```
- To remove Nginx:
  ```shell
  docker exec -it alm remove_nginx
  ```


### Building and Running Java Program
- To clean the project:
 ```shell
  docker exec -it alm mvn clean
  ```
- To package the project:
 ```shell
  docker exec -it alm mvn package
  ```
- To install the project:
 ```shell
  docker exec -it alm mvn install
  ```
- To run the Java program:
 ```shell
  docker exec -it alm java -jar target/strealer-cache-manager-1.0-SNAPSHOT.jar
  ```
