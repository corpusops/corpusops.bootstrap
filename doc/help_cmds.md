# help cmds

## build image

```
NO_SQUASH=y SKIP_FOUND_CANDIDATE_EXIT=y DEBUG=y DISTRIBS="ubuntu:16.04" ./hacking/build_images
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
