# lxc Cheat sheet

## SAMPLE configuration in inventory

`00-lxc.yml`


```yaml
---
vms:
  children:
    lxcs:
lxcs:
  children:
    lxcs_corpusops:
lxcs_corpusops: {}
burp_clients:
  children:
    compute_nodes_and_lxcs:
compute_nodes_and_lxcs:
  children:
    compute_nodes_lxcs_corpusops:
    lxcs_corpusops:
  vars:
    lxc_cluster_flavor: corpusops
    ubuntu_release: "focal"
    corpusops_lxc_ubuntu_release: "{{ubuntu_release}}"
    corpusops_localsettings_monitoring: true
    corpusops_localsettings_hostname: true
    corpusops_core_security: true
    corpusops_services_mail_postfix: true
    # lxc_compute_node: to set in hosts files
compute_nodes_lxcs:
  children:
    compute_nodes_lxcs_corpusops:
  vars:
    corpusops_do_lxc_compute_node: true
    corpusops_services_virt_lxc: true
    corpusops_services_virt_docker: true
    # to be set in host files
    # public_ip: "{{ansible_default_ipv4.address}}"
    # public_ips: ["{{public_ip}}"]
    corpusops_services_mail_postfix: true
    corpusops_localsettings_hostname: true
    corpusops_services_proxy_haproxy: true
    corpusops_services_firewall_ms_iptables: true
    corpusops_ms_iptables_registrations_registrations_lxc:
      rules: |
        {%- set r = [] %}{% set h = vars['hostvars'] %}
        {%- for i in vars['groups'].get(inventory_hostname+'_lxcs', []) %}
        {%-  set idata = h[i] %}
        {%-  set local_ip = idata['local_ip'] %}
        {%-  set ssh_port = idata['ssh_port'] %}
        {%-  set iptables = idata.get('iptables', []) %}
        {%-   for pip in ([vars.get('public_ip', '')] +
                          vars.get('public_ips', []))|copsf_uniquify %}
        {%-    if pip and pip.strip() %}
        {%-     for rule in iptables + [
          'iptables -w -t nat -A PREROUTING -d {public_ip}/32'
          ' -p tcp -m tcp --dport {ssh_port} -j DNAT'
          ' --to-destination {local_ip}:22',
          'iptables -w -t nat -A PREROUTING -d {public_ip}/32'
          ' -p udp -m udp --dport {ssh_port} -j DNAT'
          ' --to-destination {local_ip}:22',
          'iptables -w -A FORWARD    -d {public_ip}/32'
          ' -p tcp -m state --state NEW -m multiport --dports {ssh_port}'
          ' -j ACCEPT'] %}
        {%-   set _ = r.append(
               rule.format(
                 local_ip=local_ip, ssh_port=ssh_port, public_ip=pip)) %}
        {%-     endfor %}
        {%-   endif %}
        {%-  endfor %}
        {%- endfor %}
        {{- r | to_json }}
    corpusops_lxc_ssh_keys: |-
        {%- set keys = [] %}
        {%- set d = corpusops_ssh_added_keys_map['default'] %}
        {%- for i in d %}
        {%-  for j in corpusops_ssh_keys_map.get(i, []) %}
        {%-    set _ = keys.append(j) %}
        {%-  endfor %}
        {%- endfor %}
        {{- keys | to_json }}
    _corpusops_lxc:
      containers: |-
        {% set r = {} %}
        {% set h = vars['hostvars'] %}
        {%- for i in vars['groups'].get(inventory_hostname+'_lxcs', []) %}
        {%-  set hd = h[i] %}{% set cconf = r.setdefault(i, {}) %}
        {%-    for ii, ival in hd.get('lxc_data',{}).items() %}
        {%-      set _ = cconf.setdefault(ii, ival) %}
        {%-   endfor %}
        {%- endfor %}
        {{ r | to_json }}
    corpusops_haproxy_registrations_registrations_lxc: |-
      {%- set r = [] %}
      {%- for i in vars['groups'].get(inventory_hostname+'_lxcs', []) %}
      {%- set idata = vars['hostvars'][i] %}
      {%- set ip = idata.get('local_ip', i).split('/')[0] %}
      {%- set hosts = idata.get('haproxy_hosts', []) %}
      {%- set wildcards = idata.get('haproxy_wildcards', []) %}
      {%- set regexes = idata.get('haproxy_regexes', []) %}
      {%- set letsencrypt = idata.get('letsencrypt', True) %}
      {%- set letsencrypt_http_port = idata.get('letsencrypt_http_port', none) %}
      {%- set letsencrypt_tls_port = idata.get('letsencrypt_tls_port', none) %}
      {%- set ssl_terminated = idata.get('ssl_terminated', True) %}
      {%- if hosts or regexes or wildcards %}
      {%- set _ = r.extend([
        {'ip': [ip],
         'frontends': {
            80:  {'to_port': 80, 'letsencrypt': letsencrypt, 'mode': 'http'},
            443: {'to_port': 80,
                  'mode': 'https',
                  'letsencrypt': letsencrypt,
                  'letsencrypt_http_port': letsencrypt_http_port,
                  'letsencrypt_tls_port': letsencrypt_tls_port,
                  'ssl_terminated': ssl_terminated},
         },
         'hosts': hosts,
         'wildcards': wildcards,
         'regexes': regexes},
      ]) %}
      {%- endif %}
      {%- endfor %}
      {{- r | to_json }}
lxcs_ssh_bastion_vars:
  vars:
    ssh_bastion: null
  children: {"lxcs_ssh_bastion": {}}
lxcs_ssh_bastion:
  vars:
    ssh_proxycommand: "{% if ssh_bastion|default(none) %}ssh -W {{local_ip|default(ansible_host|default(inventory_hostname))}}:%p -q {{ssh_bastion}}{% endif %}"
    ansible_ssh_common_args: "{% if ssh_bastion|default(none) %}-o ProxyCommand=\"{{ssh_proxycommand}}\"{% endif %}"
  children:
    lxcs_containers:
lxcs_containers:
  children:
    lxcs_makinastates:
    lxcs_corpusops:
  vars:
    corpusops_core_security: true
    corpusops_localsettings_hostname_hostname: "{{inventory_hostname.split('.')[0]}}"
    corpusops_localsettings_hostname_fqdn: "{{inventory_hostname}}"
    ssh_bastion: "{{lxc_compute_node}}"
    ssh_port: "{{40000 + local_ip.split('.')[-1]|int  -1}}"
    lxc_data: "
        {%- set res = {} %}
        {%- set _ = res.update(lxc_data__default) %}
        {%- set _ = res.update(lxc_data__extra) %}
        {%- for i in [
          'eth0_ip', 'eth0_mac', 'eth0_gateway', 'eth0_bridge',
          'eth1_ip', 'eth1_mac', 'eth1_gateway', 'eth1_bridge',
          'eth2_ip', 'eth2_mac', 'eth2_gateway', 'eth2_bridge',
          'eth3_ip', 'eth3_mac', 'eth3_gateway', 'eth3_bridge',
          'eth4_ip', 'eth4_mac', 'eth4_gateway', 'eth4_bridge',
          'eth5_ip', 'eth5_mac', 'eth5_gateway', 'eth5_bridge',
          'eth6_ip', 'eth6_mac', 'eth6_gateway', 'eth6_bridge',
          'eth7_ip', 'eth7_mac', 'eth7_gateway', 'eth7_bridge',
          'eth8_ip', 'eth8_mac', 'eth8_gateway', 'eth8_bridge',
          'eth9_ip', 'eth9_mac', 'eth9_gateway', 'eth9_bridge',
          ] -%}                        gateway
        {%- if i in res and not res.get(i, None) %}{% set _ = res.pop(i)%}{%endif %}{%- endfor -%}
        {{- res|to_json -}}"
    lxc_data__extra: {}
    lxc_data__default:
      template_options: '-r {ubuntu_release} --mirror "{ubuntu_mirror}"'
      eth0_gateway: "{% if lxc_cluster_flavor == 'makinastates'
        %}{% set gateway='10.5.0.1'%}{%else%}{% set gateway='10.8.0.1'%}{%endif
        %}{{lxc_gateway|default(gateway)}}"
      eth0_ip: "{{local_ip}}"
      container_name: "{{inventory_hostname}}"
      from_container: corpusopsbionictpl
      docker: "{{lxc_docker|default('docker' in inventory_hostname)}}"
      ssh_keys: |-
        {%- set keys = [] %}
        {%- set c = inventory_hostname %}
        {%- set d = corpusops_ssh_added_keys_map.get('default',[])%}
        {%- for i in corpusops_ssh_added_keys_map.get(c, d) %}
        {%-  for j in corpusops_ssh_keys_map.get(i, []) %}
        {%-    set _ = keys.append(j) %}
        {%-  endfor %}
        {%- endfor %}
        {{- keys | to_json }}
```


`08-myhost.yml`


```yaml
---
ovh:
  hosts:
    f.q.d.n:
baremetals_managed:
  hosts:
    f.q.d.n:
burp_clients:
  children:
    f.q.d.n_and_lxcs:
lxcs_corpusops:
  children:
    f.q.d.n_lxcs:
compute_nodes_lxcs_corpusops:
  hosts:
    f.q.d.n:
backup5_clients:
  children:
    f.q.d.n_and_lxcs:
f.q.d.n_lxcs:
  hosts:
    vm.f.q.d.n:
f.q.d.n_and_lxcs:
  children:
    f.q.d.n_lxcs:
  hosts:
    f.q.d.n:
  vars:
    public_ip: "1.2.3.4"
    public_ips: []
    vrack_ip: 4.6.5.7
    slapd_ip: 4.2.1.3
    lxc_compute_node: f.q.d.n
g2-6n:
  hosts: {}
all:
  hosts:
    vm.f.q.d.n:
      local_ip: 10.8.0.4
      haproxy_regexes: []
      haproxy_hosts: ["{{inventory_hostname}}"]
    f.q.d.n:
      ansible_host: "{{public_ip}}"
      public_ip: "1.2.3.4"
      corpusops_ms_iptables_registrations_registrations_lxcredirects:
        rules: |
          {%- set r = [] %}{% set h = vars['hostvars'] %}
          {%- set i = 'vm.f.q.d.n' %}
          {#- slapd #}
          {%- set idata = h[i] %}
          {%- set redirected_public_ip = slapd_ip %}
          {%- set local_ip = idata['local_ip'] %}
          {%- set dports = '389,636' %}
          {%- set iptables = idata.get('iptables', []) %}
          {%- for rule in iptables + [
            'iptables -w -t nat -A OUTPUT -m addrtype --src-type LOCAL'
            ' --dst-type LOCAL -p tcp -m tcp -m multiport --dports {dports}'
            ' -j DNAT --to-destination {local_ip}',
            'iptables -w -t nat -A PREROUTING -d {redirected_public_ip}/32'
            ' -p tcp -m tcp -m multiport --dports {dports} -j DNAT'
            ' --to-destination {local_ip}',
            'iptables -w -A FORWARD    -d {redirected_public_ip}/32'
            ' -p tcp -m state --state NEW -m multiport --dports {dports}'
            ' -j ACCEPT'] %}
          {%-   set _ = r.append(
                 rule.format(
                   local_ip=local_ip, dports=dports,redirected_public_ip=redirected_public_ip)) %}
          {%-  endfor %}
          {{- r | to_json }}
```

## Configure host and create VM
### variable defs
```sh
cd /srv/corpusops/corpusops.bootstrap
export COPS_ROOT=$(pwd)
# compute node
export h=f.q.d.n
# list of vms
export vms=vm.f.q.d.n vm2.f.q.d.n
# ubuntu release
export r=focal
export inv=/etc/ansible/inventory.infra
```

### configure compute node for lxc, haproxy & iptables redirects
```sh
$COPS_ROOT/bin/ansible-playbook -vvv \
    -i $inv -l $h $COPS_ROOT/roles/corpusops.roles/playbooks/base.yml
$COPS_ROOT/bin/ansible-playbook -vvv \
    -i $inv -l $h $COPS_ROOT/roles/corpusops.roles/services_virt_docker/role.yml
$COPS_ROOT/bin/ansible-playbook -vvvv \
    -i $inv -l $h $COPS_ROOT/roles/corpusops.roles/playbooks/provision/lxc_compute_node/main.yml --skip-tags "lxc_setup,haproxy_setup,haproxy,ms_iptables,ms_iptables_setup,certbot"
```

### lxc template creation
```sh
$COPS_ROOT/bin/ansible-playbook -vvvv \
    -i $inv  \
     $COPS_ROOT/roles/corpusops.roles/playbooks/provision/lxc_container.yml \
    -e "{lxc_host: $h,
         lxc_container_name: corpusops$r,
		 cops_vars_debug: true,
         ubuntu_release: $r}"
```

### lxc image from template creation
```sh
$COPS_ROOT/bin/ansible-playbook -v \
    -i $inv \
    $COPS_ROOT/roles/corpusops.roles/playbooks/provision/lxc_container/snapshot.yml \
    -e "{lxc_host: $h, container: corpusops$r, image: corpusops${r}tpl}"
```

### stop template
```sh
$COPS_ROOT/bin/ansible-playbook -v -i $inv -l $h \
    -e "{lxc_container_name: corpusops${r}tpl}" \
    $COPS_ROOT/roles/corpusops.roles/lxc_stop/role.yml
```

#### provision a vm
```sh
for i in $vms;do
    $COPS_ROOT/bin/ansible-playbook -vvv -i $inv \
        $COPS_ROOT/roles/corpusops.roles/playbooks/provision/lxc_container.yml \
        -e "{lxc_host: $h, lxc_container_name: $i, cops_vars_debug: true}"
done
```
