# Intro

I wanted to set up a private Docker registry that might be able to serve containers to evaluate models trained with different popular ML frameworks. Unlike the Kaggle model, where only grading happens on the server, this involves testing model evaluation and grading on the server. First step involves configuring a private registry to push pytorch, opencv, tensorflow, etc. containers.

## S 1.0 - Deploy the Registry


```bash
./generate_http_auth.sh &&\
    docker stack deploy \
    --compose-file docker-compose.yml registry
```

```bash
# Log into the registry, upload a regular ole python container
docker login ${DOCKER_IP}:5000

docker tag python:3.7.4 registry.localhost/python_stable_grader
docker push registry.localhost/python_stable_grader
```

## Resources

### Nginx Config - Using as a Reverse Proxy

- [Post](http://blog.johnray.io/nginx-reverse-proxy-for-your-docker-registry) on configuring nginx to reverse proxy localhost.
