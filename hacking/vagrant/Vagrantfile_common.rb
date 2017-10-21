# -*- mode: ruby -*-
VAGRANTFILE_API_VERSION = "2"
# -- CONFIGURATION ZONE --------
# If you want to alter any configuration setting,
# put theses settings in a ./vagrant_config.yml file
# This file would contain a combinaison of those settings
# -------------o<---------------
## MACHINE_NUM
# MACHINE_NUM: 2
## Moar boxes
# MACHINES: "1" # number of machines to spawn
## PLAYBOOKS:
#  you'd better to edit via vagrantfiles, see this one and ./Vagrantfile
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
## APT
# APT_MIRROR: "http://mirror.ovh.net/ftp.ubuntu.com/ubuntu/"
# APT_MIRROR: "http://ubuntu-archive.mirrors.proxad.net/ubuntu/"
## alternate dns
# DNS_SERVERS: "8.8.8.8"
## INSTALL knobs
# SKIP_MOTD: 1
# SKIP_SYNC: 1
# SKIP_INSTALL: 1
# SKIP_INSTALL_SSHFS: 1
# SKIP_ROOTSSHKEYS_SYNC: 1
# SKIP_PLAY_PLAYBOOKS: 1
# FORCE_MOTD: 1
# FORCE_SYNC: 1
# FORCE_INSTALL: 1
# FORCE_INSTALL_SSHFS: 1
# FORCE_ROOTSSHKEYS_SYNC: 1
# FORCE_PLAY_PLAYBOOKS: 1
## Per submachine configuration
# MACHINES_CFG:
#   2: # <- Machine num
#     BOX_URI: "http://foo/m.box
# -------------o<---------------
require 'digest/md5'
require 'etc'
require 'json'
require 'open3'
require 'pathname'


class MotdPlugin < Vagrant.plugin("2")
    name "motd"
    config(self.name, :provisioner) do
        class Config < Vagrant.plugin("2", :config)
            attr_accessor :motd
        end
        Config
    end
    provisioner(self.name) do
        class Do < Vagrant.plugin("2", :provisioner)
            def provision
                eprintf @config.motd
            end
        end
        Do
    end
end

FORWARDED_MACHINE_KEYS = [
    'MEMORY', 'CPUS', 'MAX_CPU_USAGE_PERCENT', 'SERIAL',
    'APT_MIRROR', 'APT_PROXY',
    'BOX', 'BOX_URI', 'UNAME','OS_RELEASE',
    'DNS_SERVERS', 'DOMAIN',
    'HOST_MOUNTPOINT', 'PRIVATE_NETWORK']


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
  def except(*keys)
    dup.except!(*keys)
  end
  def except!(*keys)
    keys.each { |key| delete(key) }
    self
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


def deepcopy(item)
    Marshal.load(Marshal.dump(item))
end


def machine_config(cfg, machine_num, item, default=nil)
    mscfg = cfg.fetch('MACHINES_CFG', {})
    mcfg = mscfg.setdefault(machine_num, {})
    if default.nil?
        default = cfg.fetch(item, nil)
    end
    mcfg.setdefault(item, default)
    mcfg[item] = deepcopy(mcfg[item])
end


def get_hostname(cfg, machine_num)
    machines_cfg = cfg['MACHINES_CFG']
    machine_cfg = machines_cfg.setdefault(machine_num, {})
    machine_cfg['VM_HOSTNAME'] = "#{cfg['VM_HOSTNAME_PRE']}#{machine_num}"
end


def cops_inject_playbooks(opts)
    opts = opts.nil? {} || opts
    cfg = opts[:cfg]
    playbooks = opts[:playbooks]
    machine_nums = opts.fetch(:machine_nums, opts[:machine_num])
    if machine_nums.nil?
      machine_nums = (cfg['MACHINE_NUM'].to_i..
                      cfg['MACHINE_NUM'].to_i+cfg['MACHINES'].to_i-1)
    else
      iterable = false
      [Array, Range].each do |type|
        if machine_nums.is_a? type
          iterable = true
        end
      end
      if !iterable
        machine_nums = [machine_nums]
      end
    end
    # install rancher server only on first box
    machine_nums.each do |mnum|
      machine_playbooks = cfg['MACHINES_CFG'][mnum]['PLAYBOOKS']
      playbooks.each do |playbook|
          machine_playbooks.insert(-1, deepcopy(playbook))
      end
    end
    return cfg
end


def ansible_setup(ansible, cfg, machine_cfg, *args)
    ansible.verbose  = true
    ansible.playbook_command = "#{cfg['COPS_ROOT']}/bin/ansible-playbook"
    # ansible.install = false
    args.each do |arg|
        if !arg.nil?
            arg.setdefault('sudo', false)
            arg.each do |key, val|
                ansible.send("#{key}=", val)
            end
        end
    end
end


def cexec(cmd, message)
    _, stdout, stderr, wait_thr = Open3.popen3(cmd)
    while line = stdout.gets
        eprintf(line)
    end
    while line = stderr.gets
        eprintf(line)
    end
    if !wait_thr.value.success?
        raise message
    end
    return stdout, stderr, wait_thr
end


def debug(message)
    if ENV.fetch("COPS_DEBUG", false)
        puts message
    end
end


def cops_sync(cfg)
    if cfg['SKIP__SYNC']
        debug 'Skipping corpusops sync'
        return cfg
    end
    if cfg['SKIP_SYNC'].nil?
        cfg['SKIP_SYNC'] = true
        ["#{cfg['COPS_ROOT']}/roles/corpusops.roles",
         "#{cfg['COPS_ROOT']}/venv/src/ansible",
         "#{cfg['COPS_ROOT']}/venv/bin/ansible"].each do |f|
             if !File.exists?(f)
                 cfg['SKIP_SYNC'] = false
             end
         end
    end
    if cfg['SKIP_SYNC']
        debug 'Skipping corpusops sync'
        return cfg
    end
    puts "Syncing corpusops.local to #{cfg['COPS_ROOT']}\n"
    cexec("#{cfg["COPS_SYNCER"]}", "Syncing corpusops failed")
    return cfg
end


def cops_install(cfg)
    if cfg['SKIP__INSTALL']
        debug 'Skipping corpusops install'
        return cfg
    end
    if (File.exists? "#{cfg['COPS_ROOT']}/venv/bin/ansible" and
        cfg['SKIP_INSTALL'].nil?)
        cfg['SKIP_INSTALL'] = true
    end
    if cfg['SKIP_INSTALL']
        debug 'Skipping corpusops install'
        return cfg
    end
    puts "Installing corpusops.local to #{cfg['COPS_ROOT']}\n"
    cexec("#{cfg["COPS_INSTALLER"]}",
          "Installing corpusops.local failed")
    cfg = cops_sync(cfg)
    return cfg
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
    cfg['COPS_BRANCH'] = "master"
    # see bellow for cfg['COPS_INSTALLER']
    # see bellow for cfg['COPS_SYNCER']
    #
    cfg['COPS_ROOT'] = cops_path
    cfg['COPS_VAGRANT_DIR'] = File.join(cfg['COPS_ROOT'], 'hacking/vagrant')
    cfg['COPS_REL_ROOT'] = Pathname.new(cfg['COPS_ROOT']).relative_path_from(
        Pathname.new(cfg['CWD']))
    cfg['COPS_REL_VAGRANT_DIR'] = Pathname.new(cfg['COPS_VAGRANT_DIR']).relative_path_from(
        Pathname.new(cfg['CWD']))
    #
    cfg['UNAME'] = `uname`.strip
    #
    cfg['SKIP_INSTALL'] = nil
    cfg['DEBUG'] = !ENV.fetch("COPS_DEBUG", "").empty?
    cfg['SKIP_CONFIGURE_NET'] = nil
    cfg['SKIP_SYNC'] = nil
    cfg['SKIP_PLAY_PLAYBOOKS'] = nil
    cfg['SKIP_ROOTSSHKEYS_SYNC'] = nil
    cfg['SKIP_INSTALL_SSHFS'] = nil
    cfg['SKIP_CLEANUP'] = nil
    cfg['SKIP_APT_CLEANUP'] = nil
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
            {"#{cfg['COPS_REL_VAGRANT_DIR']}/playbooks/net.yml" => {}},
            {"#{cfg['COPS_REL_VAGRANT_DIR']}/playbooks/sync_rootsshkeys.yml" => {}},
            {"#{cfg['COPS_REL_VAGRANT_DIR']}/playbooks/install_sshfs.yml" => {}},
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
    cfg.setdefault('COPS_REL_ROOT', cfg['COPS_ROOT'])
    cfg.setdefault('COPS_REL_VAGRANT_DIR', cfg['COPS_VAGRANT_DIR'])
    cfg.setdefault('VM_HOST', "corpusops")
    cfg.setdefault('VM_HOSTNAME_PRE', "#{cfg['VM_HOST']}-")
    cfg.setdefault('VB_BASE_NAME_PRE', "#{cfg['VM_HOST']}")
    cfg.setdefault('VB_BASE_NAME_POST', "#{cfg['OS']} #{cfg['OS_RELEASE']}64")
    cfg.setdefault(
        "COPS_INSTALLER",
        "#{cfg['COPS_ROOT']}/bin/install.sh -b #{cfg['COPS_BRANCH']} -C -S")
    cfg.setdefault(
        "COPS_SYNCER",
        "#{cfg['COPS_ROOT']}/bin/install.sh -b #{cfg['COPS_BRANCH']} -C -s")

    # SHARED FOLDERS
    cfg.setdefault('mountpoints', {cfg['CWD'] => cfg['HOST_MOUNTPOINT']})
    # save back config to yaml (mainly for persiting corpusops)
    File.open("#{yaml_config}", 'w') {|f| f.write localcfg.to_yaml }
    # Generate each machine configuration mappings
    range_machines = cfg['MACHINE_NUM'].to_i..cfg['MACHINE_NUM'].to_i+cfg['MACHINES'].to_i-1
    range_machines.each do |machine_num|
        cfg.each do |key, val|
            if FORWARDED_MACHINE_KEYS.include? key
                machine_config(cfg, machine_num, key)
            elsif key.start_with? 'SKIP_'
                machine_config(cfg, machine_num, key)
            end
        end
        machine_cfg = machines_cfg.setdefault(machine_num, {})
        hostname = get_hostname(cfg, machine_num)
        machine_config(cfg, machine_num, 'MACHINE_NUM', machine_num)
        machine_config(cfg, machine_num, 'MACHINES', cfg['MACHINES'])
        machine_config(cfg, machine_num, 'PLAYBOOKS',
                       cfg['PLAYBOOKS'].fetch(
                         machine_num, cfg['PLAYBOOKS']['default']))
        machine_config(cfg, machine_num, 'FQDN', "#{hostname}.#{machine_cfg['DOMAIN']}")
        machine_config(cfg, machine_num, 'HOSTNAME',
                       "#{cfg['VB_BASE_NAME_PRE']}#{machine_num}")
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
                       "#{machine_cfg['PRIVATE_NETWORK']}.#{machine_num+1}")
        skip = []
        force = []
        [machine_cfg, ENV].each do |mapping|
          mapping.each do |k, v|
            if k.start_with? 'FORCE_'
              force.push(k)
              skip.push("SKIP_"+k[6..-1])
            end
            if k.start_with? 'SKIP_'
              force.push("FORCE_"+k[5..-1])
              skip.push(k)
            end
          end
        end
        [skip, force].each do |col|
          col.each do |k|
            machine_cfg.setdefault(k, ENV.fetch(k, cfg.fetch(k, false)))
          end
        end
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

                #
                copy_files = ['bin/cops_shell_common',
                 'hacking/vagrant/playbooks/scripts/install_python.sh',
                 'bin/cops_pkgmgr_install.sh']
                #
                provision_scripts = ["sudo bash $(pwd)/corpusops/install_python.sh"]
                motd = ["Provision is finished:",
                        "  Machine NUM: #{machine_cfg['MACHINE_NUM']}",
                        "  Machine IP: #{machine_cfg['PRIVATE_IP']}'",
                        "  Machine Private network: #{machine_cfg['PRIVATE_NETWORK']}",
                        "  Machine hostname: #{machine_cfg['HOSTNAME']}",
                        "  Machine domain: #{machine_cfg['DOMAIN']}",
                        "",]
                # provision shell script
                copy_files.each do |f|
                    sub.vm.provision "file",
                        source: "#{cfg['COPS_ROOT']}/#{f}",
                    destination: "~/corpusops/#{File.basename(f)}"
                end
                sub.vm.provision :shell, :inline => provision_scripts.join("\n")
                playbooksdef = [
                    {
                        "#{cfg['COPS_VAGRANT_DIR']}/playbooks/vars_files.yml" => {
                            "extra_vars" => {"provision_machines" => deepcopy(cfg),
                                             "provision_settings" => deepcopy(machine_cfg)}
                        }
                    }
                ]
                if !machine_cfg['SKIP_PLAY_PLAYBOOKS']
                    playbooksdef.push(*machine_cfg['PLAYBOOKS'])
                end
                playbooksdef.each do |playbooks|
                    playbooks.each do |playbook, variables|
                        sub.vm.provision "ansible" do |ansible|
                            ansible.playbook = playbook
                            ansible_setup(ansible, cfg, machine_cfg, variables)
                        end
                    end
                end
                if !machine_cfg['SKIP_MOTD']
                    sub.vm.provision :motd, :motd => motd.join("\n")
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
