# Docker images provision & usage
* All of our projects consider docker as a first class citizen but:
    * We still provision images with ansible: at this time **NO SECRET**, we only build general purpose image
    * We reconfigure them upon the container (re)start also with ansible, and we generally use systemd as the process supervisor.
        * Here we inject the password to decode and generate configs from secrets.
* For this, as ansible will generally need a lot of variables to manipulate the deployment, <br/>
  we need to inject first them into the docker environment, <br/>
  and this is problematic during provision as we invalidate early the build environment.
* Thus, to speed up development, we introduced the **stages**, <br/>
  which are only small dockerfiles snippets that contacatenates themselves up to complete **Dockerfiles** <br>
  that can be run separatly to test each stage indivually without needing to rebuild the whole stack everytime.
* We generally use those stages convention:
    * ``.docker/Dockerfile.stage0``: base image + code injection
    * ``.docker/Dockerfile.stage1``: code injection + OS level packages & setup
    * ``.docker/Dockerfile.stage2``: code injection + APP level packages (virtualenv, composer, bundler)
    * ``.docker/Dockerfile.stage3`` (**final**): code injection + app setup.
    * ``.docker/Dockerfile.stage4`` (**post final**): Cleanup
* Generally as a developper, you generally only have to use the main ``Dockerile``, <br/>
  and any of the other generated Dockerfiles are only needed to rebuild a subpart of the image, <br/>
  In other words, only the main, and already generated Dockerfile file will interrest you.

## Code organisation to use stages generation
* The idea is to build : **mycorp/myproject:<tag>** image
    * Thus you will at least produce this image, but we can build specific stages to debug parts of
      the build or to speed up developpment and dont redo everything from the beginning
* You need to either:
    * Place the docker snippets by lexicographical order inside a ``.docker`` folder of the top level of your repo,
    * Place them on another directory, but set the **STAGES_DIR** environment variable when you call the scripts.
* Run the ``.ansible/scripts/docker_build_stages.sh [STAGEID ... ]`` script (can be given one or more stages eg:
    * ``.ansible/scripts/docker_build_stages.sh 0 1 2 3 4``
    * ``.ansible/scripts/docker_build_stages.sh 0 1 ``
    * ``.ansible/scripts/docker_build_stages.sh 4``script will also build the other stages.
* If you use the **corpusops.bootstrap deploy scripts** (those inside **.ansible/scripts**, they will initialize the image name to ``$A_GIT_NAMESPACE/$A_GIT_PROJECT``.
