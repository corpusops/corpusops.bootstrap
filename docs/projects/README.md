# Corpusops based projects documentation

# Deploying projects
- See [deploy/variables](./deploy.md#variables) before everything else


## projects specific notes

### Drupal
- [Install the cluster](./zope.md#install_cluster)
- [Update the cluster](./drupal.md#update_cluster)
- [Get admin password](./drupal.md#password)
- [Go inside the site (admin user)](./drupal.md#duli)
- [Use drush](./drupal.md#drush)
- [Use console](./drupal.md#dconsole)
- [Update your website database](./drupal.md#ddbup)
- [vagrant: composer/vhost/nginx reload](./vagrant.md#vagredo)

### Zope
- [Install the cluster](./zope.md#install_cluster)
- [Update the cluster](./zope.md#update_cluster)
- [Get the web admin password](zope.md#password)

## Modify a project
- [Variables registries](usage.md#variables)
- [Changing a template file (eg: nginx vhost)](usage.md#variables)

## Vagrant
- [Setup variables ](./vagrant.md#variables)
- [Install vagrant and corpusops](./vagrant.md#install)
- [Start with the prebacked VM](./vagrant.md#prebacked)
- [Start from scratch](./vagrant.md#scratch)
- FAQ
    - [Where is the common ./vagrant.md code that the Vagrantfile points to](./vagrant.md#vcommon)
    - [Stop VM](./vagrant.md#stop)
    - [Start VM](./vagrant.md#tart)
    - [OMG, i launched provision but i did not want to ](./vagrant.md#stop)
    - [I shut down the provision procedure, how do I put back the sshfs link ?](./vagrant.md#mount)
    - [Going inside the vm, with ssh](./vagrant.md#sshto)
    - [Where do i link my EDITOR (IDE) & where to edit the code, in or out the VM ?](./vagrant.md#editor)
    - [Update your provision (deploy) code](./vagrant.md#upglue)
    - [Update your app code (manips git)](./vagrant.md#upcode)
    - [Symlink your project code folders](./vagrant.md#scode)
    - [Access the VM websites](./vagrant.md#vmhosts)
    - [Launch ansible commands by hand](./vagrant.md#ansiblehand)
    - [Launch ansible commands, & deploy step by step only_steps](./vagrant.md#only_steps)
    - [Override default templates](./vagrant.md#override-default-templates)

## Generic managment
- [Generic deploy doc](./deploy.md)
- [Localhost setup](./deploy.md#prepare)
- [Inventory setup](./deploy.md#inventory)
- [Servers preparation](./deploy.md#prepareservers)
- [Inventory setup](./deploy.md#inventory)
- [Install procedure](./deploy.md#install_cluster)
- [Update procedure](./deploy.md#update_cluster)

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
- [here](./start.md)
