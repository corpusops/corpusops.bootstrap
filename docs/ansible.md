# running bundled ansible integration tests with corpusops


```sh
cd $COPS_ROOT
docker rm -f copsansibletest;docker run -d \
    -v $(pwd)/venv/src/ansible:/srv/corpusops/corpusops.bootstrap/venv/src/ansible \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    --name=copsansibletest \
    corpusops/ubuntu:18.04
```

## version avec venv
```sh
docker exec -ti copsansibletest sh -c \
    'cd /srv/corpusops/corpusops.bootstrap/venv;bin/pip install -e src/ansible'
docker exec -ti copsansibletest sh -c \
    'cd /srv/corpusops/corpusops.bootstrap/venv;. bin/activate;cd src/ansible;
    test/runner/ansible-test integration -v --color yes --requirements include_role_nested'
```

## ou si python systeme
```sh
docker exec -ti copsansibletest sh -c \
  'cd /srv/corpusops/corpusops.bootstrap/venv;pip install -e src/ansible'
docker exec -ti copsansibletest sh -c \
    'cd /srv/corpusops/corpusops.bootstrap/venv/src/ansible;
     test/runner/ansible-test integration -v --color yes --requirements include_role_nested'
```

