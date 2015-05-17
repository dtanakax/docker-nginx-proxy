nginx: nginx
dockergen: docker-gen -watch -only-exposed <TLSVERIFY> -notify "nginx -s reload" /app/nginx.tmpl /etc/nginx/conf.d/default.conf
