Caddy PHP In Docker
---

# Docker Hub   
**Caddy-PHP:** [https://hub.docker.com/r/devcto/caddy-php](https://hub.docker.com/r/devcto/caddy-php)   

# Build
```bashgit clone https://github.com/skiy/docker-caddy-php.git
git clone https://github.com/skiy/docker-caddy-php.git
# like: docker build --build-arg php_image_version=8.1.0 -f Dockerfile -t caddy-php8.1 .
docker build --build-arg php_image_version=8.1.0 -f Dockerfile -t caddy-php .
docker run -d -p 80:80 caddy-php
```

# Installation
Pull the image from the docker index rather than downloading the git repo. This prevents you having to build the image on every docker host.

```sh   
docker pull devcto/caddy-php:8.1
```

# docker-compose
```yaml
version: '3'
services:
  web:
    image: devcto/caddy-php:8.1
    restart: always
    volumes:
      - ./www:/var/www/html
      - ./conf:/etc/caddy
    ports:
      - "80:80"
```

# Running
To simply run the container:

```sh
docker run --name caddy-php -p 8080:80 -d caddy-php:8.1
```
You can then browse to ```http://\<docker_host\>:8080``` to view the default install files.

# Volumes
If you want to link to your web site directory on the docker host to the container run:

```sh
docker run --name caddy-php -p 8080:80 -v /your_code_directory:/var/www/html -v ./caddyfile_conf_directory:/etc/caddy -d caddy-php:8.1
```

# License
This project is licensed under the [MIT license](LICENSE).  
