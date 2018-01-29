# helpers for docker images lifecyle managment with corpusops

## bin/build.py: Helper to construct images either from a running container or a dockerfile

### requirements
- docker > 1.13
- packer.io > 1.0
- OPT:
    - to build systemd based images, a Running linux,
      with a 3.0+ kernel (/sys/fs/cgroup mounted on your host)

### overview

- Problem with dockerfiles is that we can't control
  how a build container is run,
  nor privileged mode or volumes nor security options.

- This can be problematic where you use systemd based images
 and want to have systemd at provision time.

- The things we need:
    - Having a build strategy where we can launch a container with custom flags
      to provision as we want.
    - Having a tool that can chain builds in the proper order to consolidate the
      image creation pipeline

- For this, build.py reuse (and only support for now):
    - [hashicorp/packer](https://www.packer.io) which does most of the work.
    - Dockerfile building, idea is there to use packer
      to produce a complex baseimage, then to use
      a simple dockerfile based on the upper image
      to speed up rebuilding of the app related files
      without the need to reprovision everything from
      scratch as packer wont reuse any cache like docker.
    - we add on top a way to chain multiple packer builds
      to factorize the building chain process and
      build multiple images instead of only one.<br/>
      This is described/configured by a simple extra
      MANIFEST json file a a well known file structure:

        ```
        ./.docker/
            IMAGES.json # <- meta info about images (build order and arguments)
            builder1_type/
                builder1_file.input
            builder2_type/
                builder2_file.input
        ```


### The docker/IMAGES.json file, or how to describe images
- Process will for each image given in the images files:
    - Launch the given builder type with appropriate arguments
    - Inside the builder container, we mount all those volumes under `install`:
    - Upon success, tag the produced image
- ``docker/IMAGES.json`` is the default place, but we also provide a ``--images-files`` cli arg to override it.
- So, inside your repo create `docker/IMAGES.json` in the form:

    ```
    {
     "images": [{
       "file": "myimg.json", # file living inside docker/${builder},
       "working_dir": "../", # opt: relative to IMAGES.json
       "extra_args": "", # opt: arguments for builder
       "builder_type": "$builder"}
       }]
    }

    ```

### Construct your image with the packer builder_type
- Inside your repo create `docker/IMAGES.json` in the form:

    ```
    {
     "images": [{
       "file": "myimg.json", # file living inside docker/packer
       "working_dir": "../", # opt: relative to IMAGES.json
       "extra_args": "", # opt: arguments for packer
       "builder_type": "packer"}
       }]
    }

    ```

### Construct your image with the dockerfile builder_type
- Inside your repo create `docker/IMAGES.json` in the form:

    ```
    {
     "images": [{
       "file": "Dockerfile", # file living inside docker/packer
       "tag": "mycorp/myimg", # tag to produce
       "name": "myimg", # name part of the image,
                        default: top directory name
       "version": "1.0", # version of the image,

                           default: filewithoutext
       "working_dir": "../", # opt: relative to IMAGES.json
       "extra_args": "", # opt: arguments for packer
       "builder_type": "dockerfile"}
       }]
    }

    ```
- Eg for docker
    ```
    {
      "images": [
        {
          "tag": "corpusops/docker-matrix:v0.25.1",
          "builder_type": "docker",
          "extra_args": "--build-arg BV_SYN={img_parts[tag]}" <- wiill be formatresolved
        }
      ]
    }
    ```
- Tip: eiter define :
    - ``version+name`` (json filename is computed from version & tag)
    - ``file`` (tag name is computed from directory, and version from file string parts)

## Sumup: Steps to create corpusops docker compliant images
- Copy/adapt from another image (eg: [corpusops/elasticsearch](https://github.com/corpusops/setups.elasticsearch))
    - ``./.ansible``
    - ``./.docker``
    - ``./bin/env.sh`` (OPT)
    - ``./bin/build.sh``
- Delete ``./.docker/packer``
- Maybe adapt ``./bin/buid.sh``
- Maybe adapt ``./.docker/provision.sh``
- Feed ``.ansible/``
- Edit/adapt ``./.docker/packer.json``
    - take care that the ``__VERSION__`` placeholder is used correcly
    - edit the inline shell script to adapt the generated ``ansible_params.yml``
      ansible variable file accordingly to your provision playbooks & roles.
- Create & feed ``./.docker/IMAGES.json``
- Generate packer files with ``./bin/build.sh --generate-images``
- Launch until success ``./bin/build.sh`` which launch **docker_build_chain**.
- Verify after build:
    - generated: ``./docker/packer/*.json``
    - produced docker images

- We provide an helper script to tests image that launch an image the way packer would have
  and let you connect in the container for you to debug build procedure.
```
cd /myimage
# ( thin wrapper to $COPS_ROOT/hacking/docker_livepacker_test.sh)
bin/run_livepacker_test.sh .docker/packer/<MY_IMAGE>.json

```
