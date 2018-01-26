# Drupal specific stuff

### <a name="install_cluster"/>Install the cluster
- [Localhost setup](./deploy.md#prepare)
    - Be sure to have the password for the environment you are deploying onto except for vagrant, [see here](./deploy.md#setupvault)
    - [Review inventory and variables](./deploy.md#managevault)
- [Install procedure / Configure db](./deploy.md#install_db)
- (opt) [Install procedure / Configure db backup](./deploy.md#install_db_backup)
- [Install procedure / Configure backends](./deploy.md#install_app)

### <a name="update_cluster"/>Update the cluster
- **IF NOT ALREADY DONE**: [Localhost setup](./deploy.md#prepare)
    - Be sure to have the password for the environment you are deploying onto except for vagrant, [see here](./deploy.md#setupvault)
    - [Review inventory and variables](./deploy.md#managevault)
- (maybe opt) [Update files & glue](deploy.md#code_sync)
- (one time per env and localhost) [Do ssh setup](deploy.md#sshdeploysetup)
- [Install procedure / Configure db](./deploy.md#install_db)
- (opt) [Install procedure / Configure db backup](./deploy.md#install_db_backup)
- [Install procedure / Configure backends](./deploy.md#install_app)


## FAQ
### <a name="drush"/>Use drush
```sh
./vm_manage ssh
cd /srv/projects/<foo>/project
sbin/drush
```

### <a name="dconsole"/>Use console
```sh
./vm_manage ssh
cd /srv/projects/<foo>/project
vendor/bin/drupal
```

### <a name="ddbup"/>Update your website database
- After code update, you should also do this step

    ```sh
    # Then we go straighforward to post-update, (updb, configsync, & stuff)
    cd -
    vm_manage ssh
    root@corpusopsXX-X:~# cd /srv/projects/*/
    root@corpusopsXX-X:~# cd /srv/projects/s*/project && git submodule init
    t/
    root@corpusopsXX-X:/srv/projects/*/project# sbin/post_update.sh
    + Testing relative link /srv/projects/*/project/www/sites/default exists

     * 0- Do you want to run a drush -y updb ? [o/n]: o
      - So we run drush -y updb
     [success] No database updates required.

     * 1- Do you want to run a drush -y cim ? [o/n]: o
      - So we run drush -y cim
    + drush -y cim
     [notice] There are no changes to import.

     * 2- Clear all caches via drush ? [o/n]: o
    + drush -y cr
     [success] Cache rebuild complete.
    ```

### <a name="password"/>Get the web admin password
- Login is generally: **admin** and password can have been generated if not given explicitly (first install)
- vagrant:

    ```sh
    ./vm_manage ssh \
    'for i in /etc/*secrets/*password;do printf "$(basename $i): "$(cat $i)\\n;done'\
    |awk '!a[$0]++'|sort -nk2
    ```
- Or on a remote environment:

    ```sh
    MYENV=prod-foobar.company.com
    ssh $MYENV \
    'for i in /etc/*secrets/*password;do printf "$(basename $i): "$(cat $i)\\n;done'\
    |awk '!a[$0]++'|sort -nk2
    ```

### <a name="duli"/>Go inside the site and create an admin user
```sh
vm_manage ssh  # (or ssh $MYENV)
root@corpusopsXX-X: cd /srv/projects/*/project
root@corpusopsXX-X: sbin/drush uli
http://<project>.vbox.local/user/reset/1/xx/km-vxx/login
```
