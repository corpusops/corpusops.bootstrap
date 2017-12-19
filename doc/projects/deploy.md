# deploying corpusops based projects from localhost

## Setup vars
- Before running commands, export or adapt the commands to reflect those vars
- First, create project working dir
- review local env (git url)
```sh
$EDITOR .ansible/scripts/ansible_deploy_env.local
```

- Export variables
```sh
# project repo
export A_GIT_URL=https://gitlab.foo.net/foo/bar
export A_GIT_PROJECT=$(basename $A_GIT_URL)
export A_GIT_NAMESPACE=$(basename $(dirname($A_GIT_URL))
# local working directory
export COPS_CWD=$HOME/$A_GIT_NAMESPACE/$A_GIT_PROJECT
# deploy enviroment
export A_ENV_NAME="staging"
# local working directory
export COPS_CWD=$HOME/projects/myproject
# corpusops real place, you can change this to a more sensible place
export COPS_ROOT=$HOME/corpusops.bootstrap
# After first install (next step)
if [ ! -e "$COPS_CWD" ];then mkdir "$COPS_CWD";fi
# non interactive mode
export NONINTERACTIVE=1
```

## Prepare localhost for deployment
##  Clone project
- Attention folder must be empty for cloning directly inside it.
```sh
git clone --recursive "$A_GIT_URL" "$COPS_CWD"
# if branch is not master
# git checkout -b $A_ENV_NAME
```

# Install & keep corpusops.bootstrap up to date
- If you want to reuse a working cops, symlink it into <br/>
  ``local/corpusops.bootstrap`` before launching the script

```sh
# With a working install of corpusops inside corig_root
# ln -s $corig_root local/corpusops.bootstrap
cd $COPS_CWD
mkdir -p $COPS_ROOT local
ln -s $COPS_ROOT local/corpusops.bootstrap
.ansible/scripts/download_corpusops.sh
.ansible/scripts/setup_corpusops.sh
. .ansible/scripts/ansible_deploy_env
```

# Setup environment ssh key, vault, & inventory
## create env ssh key
- To generate a ssh keypair:
```sh
cd $COPS_CWD/local
ssh-keygen -t rsa -b 2048 -N '' -f <env_name>
ls <env_name>*
```

## Create or update env vault
The env vault contains the ssh key to deploy on environments, replace the ssh settings (pub & private by the content of the key files generated previously)

Inspire from:
- [.ansible/vaults/staging.yml](../.ansible/vaults/staging.yml)
- [.ansible/vaults/staging.clear.yml](../.ansible/vaults/staging.clear.yml)
- Create/edit vault
```sh
cd $COPS_CWD
eval "CORPUSOPS_VAULT_PASSWORD_${A_ENV_NAME}='SUPER_SECRET_PASSWORD' \
    .ansible/scripts/setup_vaults.sh"
# crypted vars (password, keys)
.ansible/scripts/edit_vault.sh
# or .ansible/scripts/edit_vault.sh .ansible/vaults/specificvault.yml
# not crypted vars
$EDITOR .ansible/vaults/${A_ENV_NAME}.clear.yml
```

## Review inventory
- Copy &/or edit the inventory to adapt to your env (``.ansible/inventory_*``)
- If you copy, think to adapt variables

## Run a deployment for a host

### Setup ansible
- Alternativly you can launch this one command to
    - Generate core vars: ``..ansible/scripts/setup_core_variables.sh``
    - Setup vault password files: ``.ansible/scripts/setup_vaults.sh``
      - think that you can also setup the
        ``CORPUSOPS_VAULT_PASSWORD_<env>`` var
        in your CI secret variables in a CI/CD env.
    - Refresh corpusops: ``.ansible/scripts/setup_corpusops.sh``
```sh
export A_ENV_NAME=staging
# Replace here SUPER_SECRET_PASSWORD by the vault password
# Note the leading " " not to have the password in bash history
 eval "CORPUSOPS_VAULT_PASSWORD_${A_ENV_NAME}='SUPER_SECRET_PASSWORD' \
.ansible/scripts/setup_ansible.sh"

# Generate SSH deploy key locally
.ansible/scripts/call_ansible.sh .ansible/playbooks/deploy_key_setup.yml

# Install python (the sole and only ansible requirementà on remote boxes
.ansible/scripts/call_ansible.sh local/corpusops.bootstrap/playbooks/corpusops/base.yml -vv

# OPT: git, vim
.ansible/scripts/call_ansible.sh --become \
    local/corpusops.bootstrap/roles/corpusops.roles/localsettings_git/role.yml \
    local/corpusops.bootstrap/roles/corpusops.roles/localsettings_vim/role.yml \
    local/corpusops.bootstrap/roles/corpusops.roles/localsettings_editor/role.yml
```

## Launch the deployment
```sh
export A_ENV_NAME=staging
# .ansible/scripts/call_ansible.sh .ansible/playbooks/<playbook>.yml
# eg:
.ansible/scripts/call_ansible.sh .ansible/playbooks/app.yml
.ansible/scripts/call_ansible.sh .ansible/playbooks/db.yml
.ansible/scripts/call_ansible.sh .ansible/playbooks/haproxy.yml
.ansible/scripts/call_ansible.sh .ansible/playbooks/db_backup.yml
```
