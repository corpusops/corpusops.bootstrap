# CORPUS OPS BOOTSTRAP PACKAGE

## INTRO
This packages helps to bring out a working ansible environment to boostrap
a whole modern infrastructure


## Installing

```$
mkdir corpusops
git clone https://github.com/corpusops/corpusops.bootstrap.git corpusops/corpusops.bootstrap
corpusops/corpusops.bootstrap/bin/install.sh -l
corpusops/corpusops.bootstrap/bin/install.sh
```

It will in ./corpusops/corpusops.bootstrap/:

    * download prerequisites packages for your distribution
    * Install a virtualenv with ansible
    * Download corpusops roles & playbooks

