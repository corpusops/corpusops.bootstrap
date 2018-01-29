# gitlab ci


# test locally the test process of a corpusops based project
to imitate how gitlab would start your project, and have
the possibility to live edit the container, process as the following

## start the container and add the user
```sh
cd $COPS_CWD
n=gitlabcidebug
docker run -ti -d --name=$n \
    -v $(readlink -f local/corpusops.bootstrap):$(pwd)/local/corpusops.bootstrap \
    -v $(pwd):$(pwd) \
    -v /sys/fs/cgroup/:/sys/fs/cgroup \
   corpusops/ubuntu:16.04
docker exec $n addgroup --gid $(id -g) $(whoami)
docker exec $n chown $(whoami) /home/$(whoami)
docker exec $n adduser --disabled-password --gecos g \
    --uid $(id -u) --gid $(id -g) $(whoami)
echo "$(whoami) ALL=(ALL) NOPASSWD:ALL" | docker exec -i $n tee /etc/sudoers.d/pw
```

