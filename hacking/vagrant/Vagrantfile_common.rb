# -*- mode: ruby -*-
# --------------------- CONFIGURATION ZONE ----------------------------------
# If you want to alter any configuration setting, put theses settings in a ./vagrant_config.yml file
# This file would contain a combinaison of those settings
# -------------o<---------------
# CPUS: 1
# MEMORY: 512
# MAX_CPU_USAGE_PERCENT: 25
## either one of: OS[/OS_RELEASE] or BOX
## OS Examples:
# OS: Ubuntu
# OS_RELEASE: 'xenial' # non mandatory
# OS: centos
# OS_RELEASE: '7' # non mandatory
## Box Examples:
# BOX: "xenial64"
# BOX: "corpusops-vagrant-ubuntu-1504-xenial64_2"
## You can set boxuri for non defaults or to override
# BOX_URI: "http://foo/xenial64.img
# ####
# APT_MIRROR: "http://mirror.ovh.net/ftp.ubuntu.com/ubuntu/"
# APT_MIRROR: "http://ubuntu-archive.mirrors.proxad.net/ubuntu/"
## alternate dns
# DNS_SERVERS: "8.8.8.8"
# MACHINES: "1" # number of machines to spawn
## INSTALL knobs
# FORCE_COPS_INSTALL: 1
# FORCE_COPS_SYNC: 1
# SKIP_SYNC_INSTALL: 1
# SKIP_ROOTSSHKEYS_SYNC: 1
# SKIP_SENDBACKTOHOST: 1
# MACHINES_CFG:
#   2:
#     BOX_URI: "http://foo/m.box
# -------------o<---------------
require 'digest/md5'
require 'etc'
require 'json'
require 'open3'
# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
# __FILE__ == ABSPATH to current Vagrantfile


def eprintf(*args)
  $stdout = STDERR
  printf(*args)
  $stdout = STDOUT
end


class Hash
  def setdefault(key, value)
    if self[key].nil?
      self[key] = value
    end
    self[key]
  end
end


# detect current host OS
def os
  @os ||= (
    host_os = RbConfig::CONFIG['host_os']
    case host_os
    when /darwin|mac os/
      :macosx
    when /linux/
      :linux
    when /solaris|bsd/
      :unix
    else
      raise Error::WebDriverError, "Non supported os: #{host_os.inspect}"
    end
  )
end


def get_uuid(cfg, machine)
    uuid_file = "#{cfg['CWD']}/.vagrant/machines/#{machine}/virtualbox/id"
    uuid = nil
    if File.exist?(uuid_file)
        uuid = File.read(uuid_file).strip()
    end
    uuid
end


def machine_config(cfg, machine_num, item, default=nil)
    mscfg = cfg.fetch('MACHINES_CFG', {})
    mcfg = mscfg.setdefault(machine_num, {})
    if default.nil?
        default = cfg.fetch(item, nil)
    end
    mcfg.setdefault(item, default)
    mcfg[item] = Marshal.load(Marshal.dump(mcfg[item]))
end


def get_hostname(cfg, machine_num)
    machines_cfg = cfg['MACHINES_CFG']
    machine_cfg = machines_cfg.setdefault(machine_num, {})
    machine_cfg['VM_HOSTNAME'] = "#{cfg['VM_HOSTNAME_PRE']}#{machine_num}"
end


def cops_inject_playbooks(cfg, playbooks)
    # install rancher server only on first box
    first_box_playbooks = cfg['MACHINES_CFG'][cfg['MACHINE_NUM']]['PLAYBOOKS']
    playbooks.each do |playbook|
        #  Play the playbook before the MOTD
        first_box_playbooks.insert(-2, playbook)
    end
    return cfg
end


def ansible_setup(ansible, cfg, *args)
    ansible.install = false
    ansible.verbose  = true
    ansible.playbook_command = "#{cfg['COPS_ROOT']}/bin/ansible-playbook"
    #ansible.playbook_command = "#{cfg['COPS_ROOT']}/bin/ansible-playbook"
    ansible.provisioning_path = cfg['HOST_MOUNTPOINT']
    if ! args.nil?
        args.each do |arg|
            if ! arg.nil?
                arg.each do |key, val|
                    ansible.send("#{key}=", val)
                end
            end
        end
    end
end


def cops_install(cfg)
    puts('cops_install not implemented')
		#if !File.exists? "#{cfg['COPS_ROOT']}/venv/bin/ansible"
    #    eprintf("Installing corpusops.local to #{cfg['COPS_ROOT']}")
		#		cmd = "#{cfg["COPS_INSTALLER"]}"
		#		rout, rerr = '', ''
		#		Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
 		#				while line = stdout.gets
    #            rout += line
		#						puts line
		#				end
		#				while line = stderr.gets
    #            rerr += line
		#						puts line
		#				end
		#		end
		#end
end


# Check entries in the configuration zone for variables available.
# --- Start Load optional config file ---------------
def cops_init(opts)
    cwd = opts.fetch(:cwd, nil)
    cops_path = opts.fetch(:cops_path, nil)
    cfg = opts.fetch(:cfg, nil)
    if cfg.nil?
        cfg = Hash.new
    end
    if cwd.nil?
        cwd = Dir.pwd
    end
    if cops_path.nil?
        tf = File.absolute_path(__FILE__)
        cops_path = File.dirname(tf)
    end
    cfg['CWD'] = cwd
    cfg['SCWD'] = cfg['CWD'].gsub(/\//, '_').slice(1..-1)
    # Number of machines to spawn
    cfg['COPS_URL'] = "https://github.com/corpusops/corpusops.bootstrap.git"
    cfg['COPS_BRANCH'] = "master"
    cfg['COPS_INSTALLER'] = "#{cfg["COPS_ROOT"]}/bin/install.sh -s -C"
    #
    cfg['COPS_ROOT'] = cops_path
    cfg['COPS_VAGRANT_DIR'] = File.join(cfg['COPS_ROOT'], 'hacking/vagrant')
    #
    cfg['UNAME'] = `uname`.strip
    #
    cfg['FORCE_COPS_PLAY_PLAYBOOKS'] = ''
    cfg['FORCE_COPS_SYNC'] = ''
    cfg['FORCE_COPS_INSTALL'] = ''
    cfg['SKIP_COPS_INSTALL'] = ''
    cfg['SKIP_COPS_SYNC'] = ''
    cfg['SKIP_COPS_PLAY_PLAYBOOKS'] = ''
    # IP managment
    # The box used a default NAT private IP and a HOST only if
    # defined automatically by vagrant and virtualbox
    cfg['DNS_SERVERS'] = '8.8.8.8'
    # Subnet
    cfg["PRIVATE_NETWORK"] = "192.168.99"
    # Number of the first machine to provision
    cfg['MACHINE_NUM'] = 1
    # Number of machines to spawn
    cfg['MACHINES'] = 1
    # Per Machine resources quotas
    cfg['DOMAIN'] = 'vbox.local'
    cfg['MEMORY'] = 3096
    cfg['CPUS'] = 2
    cfg['MAX_CPU_USAGE_PERCENT'] = 50
    cfg['AUTO_UPDATE_VBOXGUEST_ADD'] = true
    # OS
    cfg['OS'] = 'Ubuntu'
    cfg['APT_MIRROR'] = 'http://mirror.ovh.net/ftp.ubuntu.com/ubuntu/'
    cfg['APT_PROXY'] = ''
    # MAKINA STATES CONFIGURATION
    cfg['SERIAL'] = ["disconnected"]
    cfg['HOST_MOUNTPOINT'] = "/host"
    # extra provision, value in dictionnary can be either a file or a hash containing ansible variables
    cfg['PLAYBOOKS'] = {
        "default" => [
            # install docker
            {"#{cfg['COPS_VAGRANT_DIR']}/playbooks/000_net" => {}},
            {"#{cfg['COPS_VAGRANT_DIR']}/playbooks/100_sshkeys" => {}},
            {"#{cfg['COPS_VAGRANT_DIR']}/playbooks/200_corpusops" => {}},
            {"#{cfg['COPS_VAGRANT_DIR']}/playbooks/300_sshfs" => {}},
            {"#{cfg['COPS_ROOT']}/roles/corpusops.roles/services_virt_docker/role.yml" => {}},
            {"#{cfg['COPS_VAGRANT_DIR']}/playbooks/400_motd" => {}},
        ]
    }

    # load settings from a local file in case
    localcfg = Hash.new
    yaml_config = "#{cfg['CWD']}/vagrant_config.yml"
    if File.exist?(yaml_config)
      localcfg = YAML.load_file(yaml_config)
      if ! localcfg then localcfg = Hash.new end
    end
    cfg = cfg.merge(localcfg)
    # per machine overrides
    machines_cfg = cfg.setdefault('MACHINES_CFG', {})

    # OS/BOX SELECTION
    case cfg['OS']
      when /centos/i
        cfg.setdefault('OS_RELEASE', '7')
        cfg.setdefault("BOX", "centosorg#{cfg['OS_RELEASE']}64")
        cfg.setdefault('BOX_URI',
          "http://cloud.centos.org/centos/#{cfg['OS_RELEASE']}/"\
          "vagrant/x86_64/images/CentOS-#{cfg['OS_RELEASE']}.box")
      when /debian/i
        cfg.setdefault('OS_RELEASE', 'sid')
      else
        cfg.setdefault('OS_RELEASE', 'xenial')
        case cfg['OS_RELEASE']
          when /trusty|vivid/i
            cfg.setdefault("BOX", "ubuntu/#{cfg['OS_RELEASE']}64")
            cfg.setdefault("BOX_URI", nil)
          else
            cfg.setdefault("BOX", "ubuntuorg#{cfg['OS_RELEASE']}64")
            cfg.setdefault("BOX_URI",
               "https://cloud-images.ubuntu.com/"\
               "#{cfg['OS_RELEASE']}/current/"\
               "#{cfg['OS_RELEASE']}-server-cloudimg-amd64-vagrant.box")
        end
    end

    # Computed variables
    cfg.setdefault('VM_HOST', "corpusops")
    cfg.setdefault('VM_HOSTNAME_PRE', "#{cfg['VM_HOST']}-")
    cfg.setdefault('VB_BASE_NAME_PRE', "#{cfg['VM_HOST']}")
    cfg.setdefault('VB_BASE_NAME_POST', "#{cfg['OS']} #{cfg['OS_RELEASE']}64")

    # SHARED FOLDERS
    cfg.setdefault('mountpoints', {cfg['CWD'] => cfg['HOST_MOUNTPOINT']})
    # save back config to yaml (mainly for persiting corpusops)
    File.open("#{yaml_config}", 'w') {|f| f.write localcfg.to_yaml }
    # Generate each machine configuration mappings
    range_machines = cfg['MACHINE_NUM'].to_i..cfg['MACHINE_NUM'].to_i+cfg['MACHINES'].to_i-1
    range_machines.each do |machine_num|
        machine_cfg = machines_cfg.setdefault(machine_num, {})
        hostname = get_hostname(cfg, machine_num)
        machine_config(cfg, machine_num, 'MEMORY')
        machine_config(cfg, machine_num, 'CPUS')
        machine_config(cfg, machine_num, 'MAX_CPU_USAGE_PERCENT')
        machine_config(cfg, machine_num, 'SERIAL')
        machine_config(cfg, machine_num, 'APT_MIRROR')
        machine_config(cfg, machine_num, 'APT_PROXY')
        machine_config(cfg, machine_num, 'BOX')
        machine_config(cfg, machine_num, 'BOX_URI')
        machine_config(cfg, machine_num, 'COPS_ROOT')
        machine_config(cfg, machine_num, 'COPS_URL')
        machine_config(cfg, machine_num, 'DNS_SERVERS')
        machine_config(cfg, machine_num, 'DOMAIN')
        machine_config(cfg, machine_num, 'HOST_MOUNTPOINT')
        machine_config(cfg, machine_num, 'MACHINE_NUM', machine_num)
        machine_config(cfg, machine_num, 'MACHINES', cfg['MACHINES'])
        machine_config(cfg, machine_num, 'OS_RELEASE')
        machine_config(cfg, machine_num, 'PLAYBOOKS',
                       cfg['PLAYBOOKS'].fetch(machine_num, cfg['PLAYBOOKS']['default']))
        machine_config(cfg, machine_num, 'PRIVATE_NETWORK')
        machine_config(cfg, machine_num, 'UNAME')
        machine_config(cfg, machine_num, 'FORCE_COPS_INSTALL')
        machine_config(cfg, machine_num, 'FORCE_COPS_PLAY_PLAYBOOKS')
        machine_config(cfg, machine_num, 'FORCE_COPS_SYNC')
        machine_config(cfg, machine_num, 'SKIP_COPS_INSTALL')
        machine_config(cfg, machine_num, 'SKIP_COPS_PLAY_PLAYBOOKS')
        machine_config(cfg, machine_num, 'SKIP_COPS_SYNC')
        machine_config(cfg, machine_num, 'SKIP_ROOTSSHKEYS_SYNC')
        machine_config(cfg, machine_num, 'FQDN', "#{hostname}.#{machine_cfg['DOMAIN']}")
        machine_config(cfg, machine_num, 'VB_NAME',
                       "#{cfg['VB_BASE_NAME_PRE']}" \
                       " #{machine_num}" \
                       " #{cfg['VB_BASE_NAME_POST']}(#{cfg['SCWD']})")
        ssh_username = "vagrant"
        if ['xenial'].include? machine_cfg['OS_RELEASE']
            ssh_username = "ubuntu"
        end
        machine_config(cfg, machine_num, 'SSH_USERNAME', ssh_username)
        machine_config(cfg, machine_num, 'PRIVATE_IP',
                       "#{machine_cfg['PRIVATE_IP']}.#{machine_num+1}")
    end
    return cfg
end


def cops_configure(cfg)
    machines_cfg = cfg['MACHINES_CFG']
    Vagrant.configure("2") do |config|
        if Vagrant.has_plugin?('vbguest management')
           config.vbguest.auto_update = cfg['AUTO_UPDATE_VBOXGUEST_ADD']
           config.vbguest.auto_reboot = true
           config.vbguest.no_install = false
        end
        cfg['mountpoints'].each do |mountpoint, target|
          shared_folder_args = {create: true, type: "virtualbox"}
          config.vm.synced_folder(mountpoint, target, shared_folder_args)
        end
        # disable default /vagrant shared folder
        config.vm.synced_folder ".", "/vagrant", disabled: true
        range_machines = cfg['MACHINE_NUM'].to_i..cfg['MACHINE_NUM'].to_i+cfg['MACHINES'].to_i-1
        range_machines.each do |machine_num|
            machine_cfg = machines_cfg.setdefault(machine_num, {})
            machine = get_hostname(cfg, machine_num)
            config.vm.define machine do |sub|
                sub.ssh.username = machine_cfg['SSH_USERNAME']
                sub.vm.box =     machine_cfg['BOX']
                sub.vm.box_url = machine_cfg['BOX_URI']
                # do not use vagrant hostname plugin, it's evil
                # https://github.com/mitchellh/vagrant/blob/master/plugins/guests/debian/cap/change_host_name.rb#L22-L23
                sub.vm.hostname = nil
                sub.vm.network "private_network", ip: machine_cfg['PRIVATE_IP']
                sub.vm.provider "virtualbox" do |vb|
                    vb.name = machine_cfg['COPS_VB_NAME']
                end
                # vagrant 1.3 HACK: provision is now run only at first boot, we want to run it every time
                if File.exist?("#{cfg['CWD']}/.vagrant/machines/#{machine}/virtualbox/action_provision")
                    File.delete("#{cfg['CWD']}/.vagrant/machines/#{machine}/virtualbox/action_provision")
                end
                provision_scripts = [
                    "if [ ! -d /root/vagrant ];then mkdir /root/vagrant;fi;",
                    %{cat > /root/vagrant/provision_machines.json << EOF
                    #{JSON.pretty_generate(cfg)}
#EOF},
                    %{cat > /root/vagrant/provision_settings.json << EOF
                    #{JSON.pretty_generate(machine_cfg)}
#EOF},]
                # provision shell script
                provision_script = provision_scripts.join("\n")
                sub.vm.provision :shell, :inline => provision_script
                machine_cfg['PLAYBOOKS'].each do |playbooks|
                    playbooks.each do |playbook, variables|
                        sub.vm.provision "ansible" do |ansible|
                            ansible.playbook = playbook
                            ansible_setup(ansible, machine_cfg, variables)
                        end
                    end
                end
            end
        end
    end
    return cfg
end


def cops_provider_configure(cfg)
    range_machines = cfg['MACHINE_NUM'].to_i..cfg['MACHINE_NUM'].to_i+cfg['MACHINES'].to_i-1
    range_machines.each do |machine_num|
        machine_cfg = cfg['MACHINES_CFG'].setdefault(machine_num, {})
        machine = get_hostname(cfg, machine_num)
        muid = get_uuid(cfg, machine)
        Vagrant.configure("2") do |config|
            config.vm.provider :virtualbox do |vb|
                vb.customize ["modifyvm", muid, "--ioapic", "on"]
                vb.customize ["modifyvm", muid, "--memory", machine_cfg['MEMORY']]
                vb.customize ["modifyvm", muid, "--cpus", machine_cfg['CPUS']]
                vb.customize ["modifyvm", muid, "--cpuexecutioncap", machine_cfg['MAX_CPU_USAGE_PERCENT']]
                vb.customize ["modifyvm", muid, "--uartmode1"] + machine_cfg['SERIAL']
            end
        end
    end
    return cfg
end
# vim: set ft=ruby ts=2 et sts=2 tw=0 ai:
