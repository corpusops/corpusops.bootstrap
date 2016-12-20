# helper cmds

## build image

```
./hacking/docker_gen_dockerfiles;NO_SQUASH=y SKIP_FOUND_CANDIDATE_EXIT=y DEBUG=y IMAGES="ubuntu:16.04" ./hacking/build_images
```

## init_repo
```
export token=xxx
role=corpusops.vim
for i in ${role}*;do
  short=${i//corpusops./}
  cd $i
  hacking/create_repo $i
  git push -u --force git@github.com:corpusops/$short HEAD:master
  cd ..
  ansible-galaxy import corpusops $short
done
```

## list test an image
```
INITIAL_CLEANUP=1 name="c7p" docker_args=" -ti" img="corpusops/centos:7_preprovision" \
  /srv/corpusops/corpusops.bootstrap/hacking/live_test bash
INITIAL_CLEANUP=1 name="c7p" docker_args=" -ti" img="corpusops/ubuntu:16.04_preprovision" \
  /srv/corpusops/corpusops.bootstrap/hacking/live_test bash
```

## attaching pdb
```
docker exec -ti c7p /srv/corpusops/corpusops.bootstrap/venv/bin/pdb-attach
```
