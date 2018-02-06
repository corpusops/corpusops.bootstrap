# Use and modify the project deployment
## <a name="variables"/> Variables registries
- Ansible have already an incredible variables system with  default, variables, and facts but the problem there
  is that we lack the ability to merge them down up to a namespace, and
  vice-versa to flatten them back to the flat variables namespace
  without duplicating that gymnastic in a lot of places.
- For this, we introduced in corpusops two helpers:
    - An helper [corpusops.roles/vars_registry](https://github.com/corpusops/roles/tree/master/vars_registry) role which create the namespace for you.
    - Another helper: [copsf_registry](https://github.com/corpusops/roles/blob/master/ansible_plugins/filter_plugins/copsf_api.py#L1033) which acts as a ``filter plugin`` to construct those registries under the hood

### <a name="varswherehow"/> Overriding variables: where, how
- A lot of things on the templates and the deployment procedure depends on and can be altered via variables, <br/>
  those can be found inside:
    - ``.ansible/playbooks/roles/<project_name>_vars/defaults/main.yml`` on your git repository on your host (not the one in the vm).
    - of course, you have some local overrides in ``.ansible/vaults``:
        - With the ``app.yml``
        - With the ``defaults.yml``: shared amongst all projects of a defined type
          (eg: zope, drupal), you may look for reference, but most of the time this isnt where you ll place your overrides.
        - or the ``<env-based>.yml`` files.
    - See [deploy variables](deploy.md#allvars) for details on those file, and how to create new environments, with their
      encrypted, and secured vaults.

- To override a string var; simply copy/paste/edit it in a variable file (like ``vaults/app.yml``)<br/>
  which has a greater precedence from where your former variable is defined
- To override list and dicts:
    - Read [this tip](https://github.com/corpusops/roles/blob/master/vars_registry/README.md#updating-a-complex-variable-tipsntricks) about making a var becoming a *duplicated default*, as it's handy to let users update list/dicts.
        - Basically, it's as simple to just rename ``prefix_myvar`` to ``prefix_myvar___default``.
    - Then
        - put the variable in a vars file which has a greater precedence (like app.yml) and
        - To override the value, inspire from this [doc](https://github.com/corpusops/roles/blob/master/vars_registry/README.md#updating-a-complex-variable-tipsntricks), this way you will be able to concatenate/edit the former value better than overriding it completly

### <a name="ansibletemplates"/> Override default ansible templates: example for nginx
- It **may not be enough** to change variable values. and you may need time to time
  to completly alter a template for a specific project. <br/>
  Indeed, you can override most of ansible file templates that are rendered thorough the deployment,<br/>
  For this you will need two things:
    - **first**: find the original template that you need edit, eg: the nginx content vhost template.
    - **second**: make a local copy of it in your project with all needed alterations, inside ``.ansible/playbooks/overrides``.
- To find the template, it's quite certainly set in a ``templates`` subdirectory of ``.ansible/playbooks``.<br/>
  But the original may not be in your project's ``.ansible``.<br/>
  it's in your ``local/setups.XXX/.ansible/playbooks`` directory.<br/>
  Let' say I want my nginx templates:

    ```sh
    find ./local -name "*nginx*"
    ```
  - Found it: ``./local/setups.<project_name>/.ansible/playbooks/roles/<project_name>/templates/nginx.conf``.
- I'll now make a copy of this generic shared template in my local project (loosing any future shared update, by definition).
    - The local project location will be ``.ansible/playbooks/overrides``
    - and I'll add also a ``template`` subdirectory to keep it cleaner.

       ```sh
       mkdir -p .ansible/playbooks/overrides/templates
       cp ./local/setups.<project_name>/.ansible/playbooks/roles/<project_name>/templates/nginx.conf \
         .ansible/playbooks/overrides/templates/nginx.conf
       ```
    - Next step is to alter ``.ansible/playbooks/overrides/templates/nginx.conf``.
    - Then I need to tell my application that the template used is not the classical one.
      This template is referenced in a variable: ``cops_<project_name>_nginx_content_template``
        - Set in the file ``.ansible/playbooks/roles/<project_name>_vars/defaults/main.yml`` (the one we talked about at first)
        - I need to alter this template for this specific application, so that's an application override, <br/>
          this will go to ``.ansible/vaults/app/yml``:

            ```sh
            vim .ansible/vaults/app/yml
            (...)
            cops_<project_name>_nginx_content_template: "overrides/templates/nginx.conf"
            ```
- That's it, we'are almost done, you stil need two things:
    - Redeploy and test your changes on your docker/vagrant,<br/>
      see [Launch ansible commands, & deploy step by step only_steps](./vagrant.md#only_steps),<br/>
      for nginx that would be running ``call_ansible.sh`` with  ``-e "{only_steps: True, cops_<project_name>_s_setup_reverse_proxy: true, cops_<project_name>_s_reverse_proxy_reload: true}"``.
    - git-add ``.ansible/overrides`` to your copy and commit the changes in your git project

- **Note** *I could use the ansible search path and a template name clearly different than the one used in the generic case, and instead simply use ``cops_<project_name>_nginx_content_template: "foo_nginx.conf"``. Then the local template would be ``.ansible/playbooks/templates/foo_nginx.conf``, but that's not as nice, and you may have problems in the future if a ``foo_nginx.conf`` is added to the generic templates.*
