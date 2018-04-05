# Docker images provision & usage
* All of our projects consider docker as a first class citizen but:
    * We still provision images with ansible: at this time **NO SECRET**, we only build general purpose images.
    * We reconfigure them upon the container (re)start also with ansible, and we generally use ``systemd`` as the process supervisor.
    * Here we inject the password to decode and generate configs from secrets.
* For this, as ansible will generally need a lot of variables to manipulate the deployment <br/>
  and we need to load alternate build settings to adapt the procedure to a specific env,<br/>
  we use ``ansible variables yaml files`` inside the ``.ansible/vaults`` folder called vaults, one encrypted and maybe one in clear<br/>
  eg: ``.ansible/vaults/dockertest.yml`` (encrypted)  and ``.ansible/vaults/docker.clear.yml``. the  ``clear`` favor can me missing.
  Both file can be encrypted or not, ansible decrypt them via its built-in encryption mecanism, Please see corpusops Vaults managment in documentation.
* We generally use this convention for the application Dockerfiles:
    * ``Dockerfile``: base image suitable for prod (``systemd``) + code injection
    * ``docker-compose.yml``: Docker compose file sample to launch the ``prod`` image
    * ``Dockerfile.dev``: image (child of base image) that is suitable in dev (dev tools, and suitable for mounting source folder as volumes inside
    * ``docker-compose-dev.yml``: Docker compose file sample to launch the ``dev``
* You can specify the ``vault`` set you want via the ``APP_ENV_NAME=<vault>`` build arg.
* You can tell to not refresh corpusops automatically upon rebuilds via ``SKIP_COPS_UPDATE=y``
* eg:

    ```sh
    docker build --squash  -t corpusops/zope:latest . -f Dockerfile \
        [--build-arg=APP_ENV_NAME=docker] \
        [--build-arg=SKIP_COPS_UPDATE=y]
    # or
    docker build --squash  -t corpusops/zope:dev    . -f Dockerfile.dev \
        [--build-arg=APP_ENV_NAME=dockerdev] \
        [--build-arg=SKIP_COPS_UPDATE=y]
    ```
* In case you are dezbugging a build and want to speed up things:
    * You can copy/paste the Dockerfile and uncomment and read the part about ``corpusops.boostrap bind mount``<br/>
      if you are hacking yourself corpusops.bootstrap and want to load live modififications inside the build environment.
    * You can copy paste one dockerfile and adapt the ``FROM`` instruction to use a more appropriate layer, and
      adapt the desired ansible call to use ``{only_steps: true, your_step: true}``
* Build order:
    1. Build first: **mycorp/myproject:<tag>** image
    2. build: **mycorp/myproject:<dev>** image
        *  the build or to speed up developpment and dont redo everything from the beginning
    3. Build any env specific image (test, prodenv, etc).
