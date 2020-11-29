# Spawn a local docker+registry instance (dind) for testing purpose

```sh
cd hacking/localdocker
cp .env.dist .env
docker-compose build
docker-compose run --rm setup
docker-compose up -d --force-recreate
docker-compose logs -f
# when docker is started
sudo update-ca-certificates
sudo chown $(whoami) certs/*pem
```


adapt to what you may have changed in `.env`
```sh
export DOCKER_TLS_VERIFY="1" DOCKER_HOST="tcp://docker:12376" DOCKER_CERT_PATH="$HOME/corpusops/corpusops.bootstrap/hacking/localdocker/certs/client"
docker pull ubuntu
docker tag ubuntu dockerregistries:5000/foo
docker login dockerregistries:5000  # corpusops / corpusops123
docker push  dockerregistries:5000/foo
docker ps
```

