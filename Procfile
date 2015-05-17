nginx: nginx
dockergen: docker-gen -watch -only-exposed <DOCKER_TLS_VERIFY> -notify "nginx -s reload" /app/nginx.tmpl /etc/nginx/conf.d/default.conf
