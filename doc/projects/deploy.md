# Deploying corpusops based projects manually

# app

Deploying corpusops based projects manually


## sumup
- root: /home/f/namespace/myapp
- app_root:  appserver:/srv/projets/myapp/project
- data_root: appserver:/srv/projets/myapp/data
- user: myapp


## Export variables
- **Variables to export prior to inpute any commands (every time)**
- Before running commands, you have to export variables,
  certain commands still need to be adapted.

```sh
# verify
$EDITOR .ansible/scripts/ansible_deploy_env.local
# project repo
export A_GIT_URL=https://gitlab.foo.net/foo/bar
export A_GIT_PROJECT=$(basename $A_GIT_URL)
export A_GIT_NAMESPACE=$(basename $(dirname($A_GIT_URL))
# local working directory
export COPS_CWD=$HOME/$A_GIT_NAMESPACE/$A_GIT_PROJECT
# deploy enviroment *****ADAPT IT****
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



## Prepare for deployment

### Get the code
- Attention folder must be empty for cloning directly inside it.

	```sh
	git clone --recursive "$A_GIT_URL" "$COPS_CWD"
	cd $COPS_CWD
	# if branch is not master
	# git checkout -b $A_ENV_NAME
	```

### Download corpusops
- Attention local/corpusops.bootstrap folder must be empty for cloning directly inside it.

	```sh
	cd $COPS_CWD
	mkdir $COPS_ROOT local
	ln -s $COPS_ROOT local/corpusops.bootstrap
	.ansible/scripts/download_corpusops.sh
	# Replace here SUPER_SECRET_PASSWORD by the vault password
	# Note the leading " " not to have the password in bash history
	.ansible/scripts/setup_ansible.sh
	```

### Install ansible
- Via the ``.ansible/scripts/setup_ansible.sh`` we do in one GO:
    - Generate core vars: ``..ansible/scripts/setup_core_variables.sh``
    - Setup vault password files: ``.ansible/scripts/setup_vaults.sh``
      - think that you can also setup the
        ``CORPUSOPS_VAULT_PASSWORD_<env>`` var
        in your CI secret variables in a CI/CD env.
    - Refresh corpusops: ``.ansible/scripts/setup_corpusops.sh``

		```sh
		cd $COPS_CWD
		export A_ENV_NAME=<env>
		.ansible/scripts/setup_ansible.sh
		```



## Environment setup
- Create or update enviroment vault & inventory
- The env vault contains the ssh key to deploy on environments,
  replace the ssh settings (pub & private by the content of the key files generated previously)
  if not already done.

### Create/Edit/Review vault
- If your environment does not exists, inspire from:
- ``.ansible/inventory_staging``
- ``.ansible/vaults/staging.yml``
- ``.ansible/vaults/staging.clear.yml``

### Inventory setup
- Copy &/or edit the inventory to adapt to your env (``.ansible/inventory_*``)
- If you copy, think to adapt variables

### Vault passwords setup
- For each environment, setup first the ``vault password file`` that contains your vault password.

	```sh
	cd $COPS_CWD
	export A_ENV_NAME=staging
	# Replace here SUPER_SECRET_PASSWORD by the vault password
	# Note the leading " " not to have the password in bash history
	:; eval "CORPUSOPS_VAULT_PASSWORD_${A_ENV_NAME}='SUPER_SECRET_PASSWORD' \
	.ansible/scripts/setup_vaults.sh"
	```

### create env ssh key if needed
- To generate a ssh keypair if not present of you want to change it

	```sh
	cd $COPS_CWD/local
	ssh-keygen -t rsa -b 2048 -N '' -f <env_name>
	ls <env_name>*
	```
- Add it then to your crypted vault (``toto.pub`` file content in public, and the other in private)

	```yaml
	cops_deploy_ssh_key_paths:
	  clientstaging:
		path: "{{'local/.ssh/deploy_<ENV>'|copsf_abspath}}"
		pub: |-
		  ssh-rsa xxx
		private: |-
		  -----BEGIN RSA PRIVATE KEY-----
		  xxx
		  -----END RSA PRIVATE KEY-----
	```

### Encrypted vault setup
- Then edit the encrypted vaul (For passwords and other variables that need to be encrypted)

	```sh
	.ansible/scripts/edit_vault.sh
	```

### Environment vault setup
- For environment settings that does not need privary, edit the clear vault.

	```sh
	# not crypted vars
	$EDITOR .ansible/vaults/${A_ENV_NAME}.clear.yml
	```

## Servers preparation
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



## <a name="install"></a>Install procedure

### Setup deploy keys
- Generate a key from the vault for ansible to connect to remote boxes

	```sh
	# Generate SSH deploy key locally for ansible to work
	cd $COPS_CWD
	export A_ENV_NAME=<env>
	git checkout $A_ENV_NAME
	.ansible/scripts/call_ansible.sh .ansible/playbooks/deploy_key_setup.yml
	```

### <a name="install_haproxy"></a>Configure loadbalancers
- Run

	```sh
	cd $COPS_CWD
	export A_ENV_NAME=<env>
	git checkout $A_ENV_NAME
	.ansible/scripts/call_ansible.sh -vvv .ansible/playbooks/haproxy.yml
	```

### <a name="install_app"></a>Configure backends
- Run

	```sh
	cd $COPS_CWD
	export A_ENV_NAME=<env>
	git checkout $A_ENV_NAME
	.ansible/scripts/call_ansible.sh -vvv .ansible/playbooks/app.yml
	```

### <a name="install_examples"></a>Configure examples
```sh
export A_ENV_NAME=staging
# .ansible/scripts/call_ansible.sh .ansible/playbooks/<playbook>.yml
# eg:
.ansible/scripts/call_ansible.sh .ansible/playbooks/db.yml
.ansible/scripts/call_ansible.sh .ansible/playbooks/haproxy.yml
.ansible/scripts/call_ansible.sh .ansible/playbooks/db_backup.yml
.ansible/scripts/call_ansible.sh .ansible/playbooks/app.yml
```



## <a name="update"></a>Update procedure

### Get the code
- Be sure to be on the right branch & env


	```sh
	cd $COPS_CWD
	export A_ENV_NAME=<env>
	git checkout $A_ENV_NAME
	git fetch --all
	git reset --hard <COMMIT>
	# eg: staging/clientstaging/production
	git submodule update --recursive
	```

### Refresh deploy glue
- Be sure to be on the right branch & env

	```sh
	# one of: staging/clientstaging/production
	cd $COPS_CWD
	export A_ENV_NAME=<env>
	git checkout $A_ENV_NAME
	.ansible/scripts/setup_ansible.sh
	```

### Update the cluster
- Rerun: [Install procedure / Configure loadbalancers](#install_haproxy)
- Rerun: [Install procedure / Configure backends](#install_app)

