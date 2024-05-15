FROM strealer/alm-dependencies:latest

WORKDIR /alm

COPY . .

RUN cp /alm/.scripts/update_conf.sh /bin/update_conf && cp /alm/.scripts/install_nginx.sh /bin/install_nginx && cp /alm/.scripts/remove_nginx.sh /bin/remove_nginx
RUN chmod +x /bin/update_conf /bin/install_nginx /bin/remove_nginx

EXPOSE 80

# The command to start Nginx when the container starts
CMD ["nginx", "-g", "daemon off;"]
