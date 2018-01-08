# Corpusops based projects documentation

# Deploying projects
- Deploy methods
    - [Deploying on environments](./deploy.md)
    - [Deploying on vagrant](./vagrant.md)

# corpusops based projects & quickstarters
- Non exhaustive list of corpusops based projects & quickstarters
    - zope
        - [project branch](https://github.com/corpusops/setups.zope/tree/project)
        - [deploy branch](https://github.com/corpusops/setups.zope/)
    - drupal 8
        - [project branch](https://github.com/corpusops/setups.drupal/tree/D8_project)
        - [deploy branch](https://github.com/corpusops/setups.drupal/tree/D8)
- Services oriented
    - [elasticsearch](https://github.com/corpusops/setups.elasticsearch)
    - [postgresql](https://github.com/corpusops/setups.elasticsearch)
    - [dbsmartbackup](https://github.com/corpusops/setups.elasticsearch)
    - [more generally](https://github.com/corpusops?utf8=✓&q=setups.)

- Environments:
    - [Rancher](https://github.com/corpusops/setups.rancher)

- Many of the repositories have a ``project`` branch, and it's from this branch, if it exists, that you should initiate a new project, see below.

## Initiate a project

So, for example, Let's say you **initiate** a new 'toto' project (for client **Zorg**) , which is a drupal project, no other collegue as already made the stuff for you, someone should start it, and it's you.

    # prepare your local project paths
    export A_GIT_URL="git@gitlab.makina-corpus.net:zorg/toto.git"
    export COPS_CWD="$HOME/makina/zorg/vmtoto"
    # clone the gilab repo, which should be empty
    mkdir -p ${COPS_CWD}
    cd ${COPS_CWD}
    git clone ${A_GIT_URL} .
    # fetch the model project from the template project listed above
    git remote add template https://github.com/corpusops/setups.drupal.git
    git fetch --all
    # checkout the base project branche (listed above also)
    # warning: not the deploy branch, you do not need it on the new project
    # you'll get it as submodule
    git checkout -b template-deploy template/D8_project
    # and push it to the new project master branch (on origin)
    git push origin template-deploy:master
    # back on the master
    git checkout master
    git pull
    # init the project and the submodules before any customization
    # (check the other docs for details) ---------------
    git submodule init
    git submodule update --recursive
    ./.ansible/scripts/download_corpusops.sh
    # ------------------------------------------------------
    # now customize the project.
    # check .ansible/vaults/app.yml and .ansible/vaults/default.yml
    # alter the project related stuff also (like the profiles files for drupal)
    # startup code, etc.)
    # and when you are ready start the vm for the first time...
