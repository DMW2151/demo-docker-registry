# Intro

I wanted to set up a private Docker registry that might be able to serve containers to evaluate models trained with different popular ML frameworks. 
Unlike the Kaggle model, where grading happens on the server, this involves testing model evaluation and grading on the server. First step (04-07-2020) involves configuring a private registry to push pytorch, opencv, tensorflow, etc. containers.

## S.1. Deploy the Registry

```bash
docker swarm init
export CURRENT_NODE=$(docker node inspect --format '{{ .ID }}' self)
docker node update --label-add registry=true $CURRENT_NODE

docker secret create domain.crt ./registry/certs/example.crt
docker secret create domain.key ./registry/certs/example.key

docker service create --name registry \
    --secret domain.crt \
    --secret domain.key \
    --constraint 'node.labels.registry==true' \
    --mount type=bind,src="$(pwd)"/registry/data,dst=/var/lib/registry \
    -e REGISTRY_HTTP_TLS_CERTIFICATE=/run/secrets/domain.crt \
    -e REGISTRY_HTTP_TLS_KEY=/run/secrets/domain.key \
    --mount type=bind,src="$(pwd)"/registry/auth,dst=/auth \
    -e "REGISTRY_AUTH=htpasswd" \
    -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
    -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
    -p 5000:5000 \
    --replicas 1 \
    registry:2
```

## S.2. - Optional Nginx Config

See this [great post](http://blog.johnray.io/nginx-reverse-proxy-for-your-docker-registry), configure nginx to reverse proxy localhost to a friendly name.

```bash
# Get Last Running Container and Link to NGINX
export REGISTRY_CONTAINER=$( docker ps --format "{{.Names}}" | head -n 1)

docker run -d --restart=always --name nginx \
    -v $(pwd)/registry/conf/reg.conf:/etc/nginx/conf.d/default.conf \
    -v $(pwd)/registry/certs:/etc/nginx/certs \
    -p 443:443 \
    --link $REGISTRY_CONTAINER:reg nginx
```

## S.3. Push to Registry

On Mac-OS: `Error saving credentials: error storing credentials...` persists until OSX Keychain is locked and unlocked.

```bash
docker login registry.localhost:443

# Replace regular ole python as grader, sample ML environment
docker tag python:3.7.4 registry.localhost/python_stable_grader
docker push registry.localhost/python_stable_grader
```

## Appendix: Notes on SSL + HTTP AUTH; prereqs for security stuff

```bash
mkdir -p ./registry/auth ./registry/certs ./registry/data

# On the Registry Host
openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
    -keyout ./registry/certs/example.key \
    -out ./registry/certs/example.crt \
    -subj "/CN=example.com" \
    -addext "subjectAltName=DNS:localhost,IP:192.168.1.5"
```

```bash
# On the Client
cp  ./registry/certs/example.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
sudo service docker restart
```

```bash
export DOCKER_ADMIN=XXXXXXXXXX
export DOCKER_ADMIN_PWD=XXXXXXXXXX
# On the Registry Host..
sudo apt-get install apache2-utils
htpasswd -Bbn  $DOCKER_ADMIN $DOCKER_ADMIN_PWD > ./registry/auth/htpasswd
```