# Set the base image
FROM dtanakax/nginx:1.8.0

# File Author / Maintainer
MAINTAINER Daisuke Tanaka, dtanakax@gmail.com

# Environment Variable of Dockergen
# DOCKER_GEN_OS linux darwin
# DOCKER_GEN_ARCH amd64 armel armhf i386
ENV DOCKER_GEN_OS linux
ENV DOCKER_GEN_ARCH amd64
ENV DOCKER_GEN_VERSION 0.3.9

# Configure Nginx and apply fix for very long server names
RUN sed -i 's/^http {/&\n    server_names_hash_bucket_size 128;/g' /etc/nginx/nginx.conf

# Install Forego
RUN wget -P /usr/local/bin https://godist.herokuapp.com/projects/ddollar/forego/releases/current/linux-amd64/forego && \
    chmod u+x /usr/local/bin/forego

# Install Dockergen
RUN wget https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-$DOCKER_GEN_OS-$DOCKER_GEN_ARCH-$DOCKER_GEN_VERSION.tar.gz \
 && tar -C /usr/local/bin -xvzf docker-gen-$DOCKER_GEN_OS-$DOCKER_GEN_ARCH-$DOCKER_GEN_VERSION.tar.gz \
 && rm /docker-gen-$DOCKER_GEN_OS-$DOCKER_GEN_ARCH-$DOCKER_GEN_VERSION.tar.gz

ENV DOCKER_HOST unix:///tmp/docker.sock
ENV DOCKER_TLS_VERIFY false

COPY nginx.tmpl ./app/
COPY Procfile ./
COPY start.sh ./
RUN chmod +x ./start.sh

ENTRYPOINT ["./start.sh"]

# Define mountable directories.
VOLUME ["/etc/nginx/certs", "/etc/nginx/htpasswd", "/certs"]

# Executing forego
CMD ["forego", "start", "-r"]