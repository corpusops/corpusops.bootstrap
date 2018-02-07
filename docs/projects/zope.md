# Zope specific stuff

### <a name="install_cluster"/>Install the cluster
- [Localhost setup](deploy.md#prepare)
    - Be sure to have the password for the environment you are deploying onto except for vagrant, [see here](deploy.md#setupvault)
    - [Review inventory and variables](deploy.md#managevault)
- (one time per env and localhost) [Do ssh setup](deploy.md#sshdeploysetup)
- [Install procedure / Configure loadbalancers](deploy.md#install_haproxy)
- [Install procedure / Configure backends](deploy.md#install_app)

### <a name="update_cluster"/>Update the cluster
- **IF NOT ALREADY DONE**: [Localhost setup](deploy.md#prepare)
    - Be sure to have the password for the environment you are deploying onto except for vagrant, [see here](deploy.md#setupvault)
    - [Review inventory and variables](deploy.md#managevault)
- (maybe opt) [Update files & glue](deploy.md#code_sync)
- (one time per env and localhost) [Do ssh setup](deploy.md#sshdeploysetup)
- [Install procedure / Configure loadbalancers](deploy.md#install_haproxy)
- [Install procedure / Configure backends](deploy.md#install_app)

## FAQ
### <a name="password"/>Get the web admin password
- Login is generally: **admin** and password can have been generated if not given explicitly (first install)
```sh
vm_manage ssh \
'for i in /etc/*secrets/*password;do printf "$(basename $i): "$(cat $i)\\n;done'\
|awk '!a[$0]++'|sort -nk2
```

### <a name="varsedit"/>Override variables (packages, passwords, etc)
- [See here](usage.md#varswherehow)

### <a name="templatesedit"/>Override nginx (or any file) templates
- [See here](usage.md#ansibletemplates)

### <a name="seevar"/> vagrant: get variables registry
```sh
.ansible/scripts/call_ansible.sh -vvvvv \
    --inventory-file=.vagrant/provisioners/ansible/inventory \
    -e@.ansible/vaults/vagrant.yml \
    .ansible/playbooks/site*vag*l \
    -e "{only_steps: True, cops_vars_debug: true, cops_drupal_s_vars: true}" \
    --skip-tags cops_zope_lifecycle_app_push_code,cops_zope_lifecycle_app_setup
```
