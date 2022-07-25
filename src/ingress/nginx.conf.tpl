events { 
    worker_connections 1024;
}

http {
    upstream odata {
        server ${odata_host}:5001;
    }

    upstream vault {
        server ${vault_host}:8200;
    }

    include /etc/nginx/conf.d/*.conf;

    access_log syslog:server=${logger_host}:${logger_port},tag=nginx_access  json_log;
    error_log syslog:server=${logger_host}:${logger_port},tag=nginx_error info;

    server {
        listen 80;
        return 301 https://$host$request_uri;
    }

    server {
        listen 443 ssl;
        ssl_certificate       /run/secrets/ingress.crt;
        ssl_certificate_key   /run/secrets/ingress.key;
    
        location /v1/pki/ca/pem {
            proxy_pass http://vault;
        }
        
        location /v1/pki/crl {
            proxy_pass http://vault;
        }

        location /v1/pki_int/ca/pem {
            proxy_pass http://vault;
        }
        
        location /v1/pki_int/crl {
            proxy_pass http://vault;
        }

        location /idmrestapi {
            proxy_pass http://odata;
        }

        location /sap {
            proxy_pass http://odata;
        }

        location /{
            root /var/www; 
            try_files $uri $uri/ =404;
        }

        location /gencert {
            proxy_pass http://odata;
        }
    }

    
}