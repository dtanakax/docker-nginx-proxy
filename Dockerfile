# Set the base image
FROM nginx:1.7.10

# File Author / Maintainer
MAINTAINER tanaka@infocorpus.com

# Environment Variable of Dockergen
# DOCKER_GEN_OS linux darwin
# DOCKER_GEN_ARCH amd64 armel armhf i386
ENV DOCKER_GEN_OS linux
ENV DOCKER_GEN_ARCH amd64
ENV DOCKER_GEN_VERSION 0.3.9

# Install wget and install/updates certificates
RUN apt-get update && \
    apt-get install -y -q --no-install-recommends ca-certificates wget && \
    apt-get clean && \
    rm -r /var/lib/apt/lists/*

# Configure Nginx and apply fix for very long server names
RUN echo "daemon off;" >> /etc/nginx/nginx.conf && \
    sed -i 's/^http {/&\n    server_names_hash_bucket_size 128;/g' /etc/nginx/nginx.conf

# Install Forego
RUN wget -P /usr/local/bin https://godist.herokuapp.com/projects/ddollar/forego/releases/current/linux-amd64/forego && \
    chmod u+x /usr/local/bin/forego

# Install Dockergen
RUN wget https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-$DOCKER_GEN_OS-$DOCKER_GEN_ARCH-$DOCKER_GEN_VERSION.tar.gz \
 && tar -C /usr/local/bin -xvzf docker-gen-$DOCKER_GEN_OS-$DOCKER_GEN_ARCH-$DOCKER_GEN_VERSION.tar.gz \
 && rm /docker-gen-$DOCKER_GEN_OS-$DOCKER_GEN_ARCH-$DOCKER_GEN_VERSION.tar.gz

ENV DOCKER_HOST unix:///tmp/docker.sock

COPY . /app/
WORKDIR /app/

# Define mountable directories.
VOLUME ["/etc/nginx/certs"]

# Executing forego
CMD ["forego", "start", "-r"]