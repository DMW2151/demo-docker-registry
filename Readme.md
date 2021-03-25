# Intro

I wanted to set up a private Docker registry that might be able to serve containers to evaluate models trained with different popular ML frameworks. Unlike the Kaggle model, where only grading happens on the server, this involves testing model evaluation and grading on the server. First step involves configuring a private registry to push pytorch, opencv, tensorflow, etc. containers.

## S 1.0 - Deploy the Registry

The following generates a self signed cert, generates an htpasswd file, and then deploys the stack of Nginx and the registry to a swarm node. Redis is also included in the stack to get (slightly) improved performance on layer caching.

```bash
# This will work if testing on localhost ONLY
bash ./auth/generate_http_auth.sh &&\
    sudo docker stack deploy \
    --compose-file docker-compose.yml registry
```

This will almost certainly give you a x509 Error unless the registry is run on the same machine as the client. To handle for x509 errors, you'd want to use a real CA (like [LetsEncrypt](https://certbot.eff.org/lets-encrypt/ubuntubionic-nginx)) or something real-adjacent like mkcert. **For Development** one could just use `mkcert $DOCKER_HOST` on the client machine in lieu of the `openssl` command in the `./auth/generate_http_auth.sh` script.

The benefit of the included nginx configuration is that now http traffic can be upgraded to https and routed to the registry. Alternativley, all ports but `443` or `80` could be firewalled and all traffic routed to a variety of applications with the server and location blocks via nginx.

```bash
# sudo docker login localhost/registry OR ${DOCKER_IP}/registry
docker login ${DOCKER_IP}

docker tag python:3.7.4 ${DOCKER_IP}/python_stable_grader
docker push ${DOCKER_IP}/python_stable_grader
```

Alternatively, you could elect not to use Nginx or Redis at all, just run the registry on `443` and have it handle SSL termination itself with the following command:

```bash
docker run -d \
  -p 443:443 \
  --restart=always \
  --name registry \
  -v "$(pwd)"/auth:/auth \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  -v "$(pwd)"/certs:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  registry:2
```