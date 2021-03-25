# Generate Host Cert && Key
openssl req -x509 -newkey rsa:4096 -sha256 -days 365 -nodes \
    -keyout ./certs/example.key \
    -out ./certs/example.crt \
    -subj "/CN=${PUBLIC_DNS}" \
    -addext "subjectAltName=DNS:${DOCKER_HOST},IP:${DOCKER_IP}"

# Start Swarm && Join as Manager && Add Cert to Docker Secrets && Generate Registry
htpasswd -Bbn $DOCKER_ADMIN $DOCKER_ADMIN_PWD > ./htpasswd


