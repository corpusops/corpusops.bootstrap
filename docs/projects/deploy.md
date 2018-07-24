# Deploying corpusops based projects manually

# app
Deploying corpusops based projects manually

## sumup
- repo ($A_GIT_URL): https://gitlab.foo.net/foo/bar
- root ($COPS_CWD): ``/home/f/namespace/myapp``
- app_root:  ``appserver:/srv/projets/myapp/project``
- data_root: ``appserver:/srv/projets/myapp/data``
- user: ``myapp``

## <a name="prepare"/>Prepare localhost for deployment

### <a name="get"/>Prepare context
- Attention folder must be empty for cloning directly inside it.

    ```sh
    export A_GIT_URL=https://gitlab.foo.net/foo/bar
    export COPS_CWD=/home/f/namespace/myapp
    git clone --recursive "$A_GIT_URL" "$COPS_CWD"
    cd $COPS_CWD
    # if branch is not master
    # git checkout -b $A_ENV_NAME
    git submodule init
    git submodule update
    ```

### <a name="get"/>Verify core variables are in place
- Before everything else, verify that setup for identifying your project is done

    ```sh
    # verify adapt
    $EDITOR .ansible/scripts/ansible_deploy_env.local
    # should contain at least: project namespace: $A_GIT_NAMESPACE & repo: $A_GIT_PROJECT+
    # those 2 vars control also the path to the local vault password when you have to deploy to remote environments
    # and certainly git server $A_GIT_SERVER), & git url $A_GIT_URL: ${A_GIT_SERVER}/$A_GIT_NAMESPACE/$A_GIT_PROJECT
    ``` 


### <a name="download"/>Download corpusops
- Attention local/corpusops.bootstrap folder must be empty for cloning directly inside it.

    ```sh
    cd $COPS_CWD
    .ansible/scripts/download_corpusops.sh
    .ansible/scripts/setup_ansible.sh
    ```

### <a name="install_ansible"/>Install ansible
- Via the ``.ansible/scripts/setup_ansible.sh`` we do in one GO:
    - Generate core vars: ``.ansible/scripts/setup_core_variables.sh``
    - Setup vault password files: ``.ansible/scripts/setup_vaults.sh``
      - think that you can also setup the
        ``CORPUSOPS_VAULT_PASSWORD_<env>`` var <br/>
        in your CI secret variables in a CI/CD env.
    - Refresh corpusops: ``.ansible/scripts/setup_corpusops.sh``

        ```sh
        cd $COPS_CWD
        export A_ENV_NAME=<env>
        .ansible/scripts/setup_ansible.sh
        ```

## <a name="inventory"/>Inventory setup
- The inventory in corpusops projects is based on an inventory file and two inline variables files.
    - ``.ansible/inventory_staging``: inventory
    - ``.ansible/vaults/staging.yml``: encrypted variables (passwords, keys)
    - ``.ansible/vaults/staging.clear.yml``: env specific non sensitive vars (hostname)

- <a name="allvars"/> To adapt variables, you can review all the default variables inside (less to most priority):
    - ``./ansible/playbooks/roles/*/default.yml``
    - ``./ansible/vaults/default.yml``
    - ``./ansible/vaults/app.yml``

- [Setup the environment password](./deploy.md#setupvault)
- [Create the private vault](./deploy.md#managevault) if not done
- <a name="allvarsenv"/> Copy &/or edit the (default or any) inventory to adapt to your env<br/>
   (eg: ``.ansible/inventory_<env>`` && ``.ansible/env*.yml``)<br/>

   and if you copy, do not forget to adapt variables.
    - If your environment does not exists, inspire from: ``.ansible/inventory_staging``
    - And the associated inline ansible variables files (that you will surely edit):
        - ``.ansible/vaults/staging.clear.yml``: put here any env specific and non sensitive vars (hostname)
        - ``.ansible/vaults/staging.yml``: encrypted variables (passwords, keys)
            - **Do not use YOUR PERSONAL SSH KEY HERE**
            - This one should contains the ssh key to deploy on environments,
              replace the ssh settings (pub & private by the content of the key files
            - [Generate a key](./deploy.md#sshkeygen) if you don't have any key
            - [Put the key in the vault](./deploy.md#sshkeyvaultsetup)
            - Update the inventory to use that key (adapt existing hosts)
- The vagrant and docker envs are resp. **vagrant** & **docker**.
- For details on how to edit variables, see [modify variables](usage.md#varswherehow)


### <a name="setupvault"/>Vault passwords setup
- For each environment, setup first the ``vault password file`` that contains your vault password.

    ```sh
    cd $COPS_CWD
    export A_ENV_NAME=staging
    # Replace here SUPER_SECRET_PASSWORD by the vault password
    # Note the leading " " not to have the password in bash history
    :; eval "CORPUSOPS_VAULT_PASSWORD_${A_ENV_NAME}='SUPER_SECRET_PASSWORD' \
    .ansible/scripts/setup_vaults.sh"
    ```

### <a name="sshkeyvaultsetup"/>Configure ssh keys in vault
- Add it then to your crypted vault (``toto.pub`` file content in public, and the other in private)

    ```sh
    # export A_ENV_NAME=<env>
    .ansible/scripts/edit_vault.sh
    ```

- will open a terminal with your vault

    ```yaml
    cops_deploy_ssh_key_paths:
      # replace by your env id used in the host definition inside your former inventory
      staging:
        path: "{{'local/.ssh/deploy_<ENV>'|copsf_abspath}}"
        pub: |-
          ssh-rsa xxx
        private: |-
          -----BEGIN RSA PRIVATE KEY-----
          xxx
          -----END RSA PRIVATE KEY-----
    ```

- To <a name="sshkeygen"/> generate a ssh keypair if not present inside your secret vault of you want to change it

    ```sh
    cd $COPS_CWD/local
    export A_ENV_NAME=staging
    ssh-keygen -t rsa -b 2048 -N '' -C $A_ENV_NAME -f $A_ENV_NAME
    ls <env_name>*
    ```

### <a name="managevault"/>Create/Edit/Review crypted vault
- Then edit the encrypted vault (For passwords and other variables that need to be encrypted)

    ```sh
    # export A_ENV_NAME=<env>
    .ansible/scripts/edit_vault.sh
    ```

## <a name="prepareservers"/> Servers preparation
- Copy the public deploy key in every server ``~/.ssh/authorized_keys``

### Setup remote boxes for ansible control
- This will install python on target boxes

    ```sh
    # Install python (the sole and only ansible requirementà on remote boxes
    .ansible/scripts/call_ansible.sh local/corpusops.bootstrap/playbooks/corpusops/base.yml -vv
    ```

### Setup core tools
- Configure git, vim, screen

    ```sh
    cd $COPS_CWD
    export A_ENV_NAME=<env>
    git checkout $A_ENV_NAME
    # OPT: git, vim
    .ansible/scripts/call_ansible.sh --become \
        local/corpusops.bootstrap/roles/corpusops.roles/localsettings_screen/role.yml \
        local/corpusops.bootstrap/roles/corpusops.roles/localsettings_git/role.yml \
        local/corpusops.bootstrap/roles/corpusops.roles/localsettings_vim/role.yml \
        local/corpusops.bootstrap/roles/corpusops.roles/localsettings_editor/role.yml
    ```

### <a name="sshdeploysetup"></a>GENERIC ssh setup
- Generate a key from the vault for ansible to connect to remote boxes

    ```sh
    # Generate SSH deploy key locally for ansible to work and dump
    # the ssh key contained in inventory in a place suitable
    # by ssh client (ansible)
    cd $COPS_CWD
    export A_ENV_NAME=<env>
    git checkout $A_ENV_NAME
    .ansible/scripts/call_ansible.sh .ansible/playbooks/deploy_key_setup.yml
    ```

## <a name="install_cluster"></a>GENERIC Install procedure step
- **see your project specific documentation**
    - [zope](./zope.md#install_cluster)
    - [drupal](./drupal.md#install_cluster)

### <a name="install_db"></a>Configure db
```sh
cd $COPS_CWD
export A_ENV_NAME=<env>
git checkout $A_ENV_NAME
.ansible/scripts/call_ansible.sh -vvv .ansible/playbooks/db.yml
```

### <a name="install_db_backup"></a>Configure db backup
```sh
cd $COPS_CWD
export A_ENV_NAME=<env>
git checkout $A_ENV_NAME
.ansible/scripts/call_ansible.sh -vvv .ansible/playbooks/db_backup.yml
```

### <a name="install_haproxy"></a>Configure haproxy
```sh
cd $COPS_CWD
export A_ENV_NAME=<env>
git checkout $A_ENV_NAME
.ansible/scripts/call_ansible.sh -vvv .ansible/playbooks/haproxy.yml
```

### <a name="install_app"></a>Configure application
```sh
cd $COPS_CWD
export A_ENV_NAME=<env>
git checkout $A_ENV_NAME
.ansible/scripts/call_ansible.sh -vvv .ansible/playbooks/app.yml
```

## <a name="update_cluster"/>Update procedure

### <a name="code_sync"/>Update the files

#### <a name="update_code"/>Update the code
- Be sure to be on the right branch & env

    ```sh
    cd $COPS_CWD
    export A_ENV_NAME=<env>
    git checkout $A_ENV_NAME
    git fetch --all
    git reset --hard <COMMIT>
    # eg: staging/clientstaging/production
    git submodule init
    git submodule update --recursive
    ```

#### <a name="refresh_glue"/>Refresh deploy glue
- Be sure to be on the right branch & env

    ```sh
    # certainly one of: staging/production
    cd $COPS_CWD
    export A_ENV_NAME=<env>
    git checkout $A_ENV_NAME
    .ansible/scripts/setup_ansible.sh
    ```

### <a name="do_upgrade"/>Run the upgrade
- [drupal](./drupal.md#update_cluster)
- [zope](./zope.md#update_cluster)
