# running bundled ansible integration tests with corpusops


```sh
cd $COPS_ROOT
docker rm -f copsansibletest;docker run -d \
    -v $(pwd)/venv/src/ansible:/srv/corpusops/corpusops.bootstrap/venv/src/ansible \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    --name=copsansibletest \
    corpusops/ubuntu:16.04
docker exec -ti copsansibletest sh -c \
    'cd /srv/corpusops/corpusops.bootstrap/venv;bin/pip install -e src/ansible'

docker exec -ti copsansibletest sh -c \
'cd /srv/corpusops/corpusops.bootstrap/venv;. bin/activate;cd src/ansible;
test/runner/test.py integration -v --color yes --requirements include_role_nested'
```
