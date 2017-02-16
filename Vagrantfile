# -*- mode: ruby -*-
# vim: set ft=ruby ts=2 et sts=2 tw=0 ai:
# --------------------- CONFIGURATION ZONE ----------------------------------
# If you want to alter any configuration setting, put theses settings in a ./vagrant_config.yml file
# This file would contain a combinaison of those settings
# -------------o<---------------
# CORPUSOPS_NUM: 3
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
# APT_MIRROR: "http://mirror.ovh.net/ftp.ubuntu.com/"
# APT_MIRROR: "http://ubuntu-archive.mirrors.proxad.net/ubuntu/"
## alternate dns
# DNS_SERVERS: "8.8.8.8"
# MACHINES: "1" # number of machines to spawn
## INSTALL knobs
# FORCE_INSTALL: 1
# FORCE_SYNC: 1
# SKIP_INSTALL: 1
# SKIP_ROOTSSHKEYS_SYNC: 1
# -------------o<---------------
require 'yaml'
require 'digest/md5'
require 'etc'
# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
# __FILE__ == ABSPATH to current Vagrantfile
CWD = File.dirname(__FILE__)
SCWD = CWD.gsub(/\//, '_').slice(1..-1)

def eprintf(*args)
  $stdout = STDERR
  printf(*args)
  $stdout = STDOUT
end

class Hash
  def setdefault(key, value)
    if self[key].nil?
      self[key] = value
    else
      self[key]
    end
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

# Check entries in the configuration zone for variables available.
# --- Start Load optional config file ---------------
def get_uuid(machine)
    uuid_file = "#{CWD}/.vagrant/machines/#{machine}/virtualbox/id"
    uuid = nil
    if File.exist?(uuid_file)
        uuid = File.read(uuid_file).strip()
    end
    uuid
end

cfg = Hash.new
# Number of machines to spawn
cfg['CORPUSOPS_NUM'] = nil
cfg['UNAME'] = `uname`.strip
cfg['FORCE_INSTALL'] = ''
cfg['FORCE_SYNC'] = ''
# Number of machines to spawn
cfg['MACHINES'] = 1
# Per Machine resources quotas
cfg['DOMAIN'] = 'local'
cfg['MEMORY'] = 1024
cfg['CPUS'] = 2
cfg['MAX_CPU_USAGE_PERCENT'] = 50
# network & misc corpusops settings
cfg['CORPUSOPS_AUTO_UPDATE'] = true
cfg['AUTO_UPDATE_VBOXGUEST_ADD'] = true
cfg['DNS_SERVERS'] = '8.8.8.8'
# OS
cfg['OS'] = 'Ubuntu'
cfg['APT_MIRROR'] = 'http://fr.archive.ubuntu.com/ubuntu'
cfg['APT_PROXY'] = ''
# MAKINA STATES CONFIGURATION
cfg['SERIAL'] = ["disconnected"]
# load settings from a local file in case
localcfg = Hash.new
VSETTINGS_Y = "#{CWD}/vagrant_config.yml"
if File.exist?(VSETTINGS_Y)
  localcfg = YAML.load_file(VSETTINGS_Y)
  if ! localcfg then localcfg = Hash.new end
end
cfg = cfg.merge(localcfg)

# Can be overidden by env. (used by manage.sh import/export)
cfg.each_pair { |i, val| cfg[i] = ENV.fetch("CORPUSOPS_#{i}", val) }
['BOX', 'BOX_URI'].each do |i|
    val = ENV.fetch("CORPUSOPS_#{i}", nil)
    if val != nil then cfg[i] = val end
end

# IP managment
# The box used a default NAT private IP, defined automatically by vagrant and virtualbox
if not cfg['CORPUSOPS_NUM']
    consumed_nums = []
    skipped_nums = ["1", "254"]
    `VBoxManage list vms|grep -i corpusops`.split(/\n/).each do |l|
      n = l.downcase.sub(/.*corpusops ([0-9]*) .*/, '\\1')
      if not consumed_nums.include?(n) and not n.empty?
          consumed_nums << n
      end
    end
    ("1".."254").each do |num|
      if !consumed_nums.include?(num) && !skipped_nums.include?(num)
        cfg['CORPUSOPS_NUM'] = num
        break
      end
    end
    if not cfg['CORPUSOPS_NUM']
      raise "There is no corpusops numbers left in (#{consumed_nums})"
    end
end
localcfg['CORPUSOPS_NUM'] = cfg['CORPUSOPS_NUM']

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

# save back config to yaml (mainly for persiting corpusops)
File.open("#{VSETTINGS_Y}", 'w') {|f| f.write localcfg.to_yaml }

#------------ SHARED FOLDERS ----------------------------
mountpoints = {CWD => "/srv/corpusops/corpusops.bootstrap"}

#------------ Computed variables ------------------------
cfg['VIRTUALBOX_BASE_VM_NAME'] = "corpusops #{cfg['CORPUSOPS_NUM']} #{cfg['OS']} #{cfg['OS_RELEASE']}64"
cfg['VM_HOST'] = "corpusops#{cfg['CORPUSOPS_NUM']}"

Vagrant.configure("2") do |config|
  if Vagrant.has_plugin?('vbguest management')
     config.vbguest.auto_update = cfg['AUTO_UPDATE_VBOXGUEST_ADD']
     config.vbguest.auto_reboot = true
     config.vbguest.no_install = false
  end
  mountpoints.each do |mountpoint, target|
    shared_folder_args = {create: true, type: "virtualbox"}
    config.vm.synced_folder(mountpoint, target, shared_folder_args)
  end
  # disable default /vagrant shared folder
  config.vm.synced_folder ".", "/vagrant", disabled: true
  (1..cfg['MACHINES'].to_i).each do |machine_num|
     hostname = "#{cfg['VM_HOST']}-#{machine_num}"
     machine = hostname
     config.vm.define  machine do |sub|
       virtualbox_vm_name = "#{cfg['VIRTUALBOX_BASE_VM_NAME']} #{machine_num} (#{SCWD})"
       cfg['SSH_USERNAME'] = if ['xenial'].include? cfg['OS_RELEASE']
                             then "ubuntu"
                             else "vagrant"
                             end
       sub.ssh.username = cfg['SSH_USERNAME']
       sub.vm.box = cfg['BOX']
       sub.vm.box_url = cfg['BOX_URI']
       fqdn = "#{hostname}.#{cfg['DOMAIN']}"
       # do not use vagrant hostname plugin, it's evil
       # https://github.com/mitchellh/vagrant/blob/master/plugins/guests/debian/cap/change_host_name.rb#L22-L23
       sub.vm.hostname = nil
       sub.vm.provider "virtualbox" do |vb|
           vb.name = "#{virtualbox_vm_name}"
       end
       # vagrant 1.3 HACK: provision is now run only at first boot, we want to run it every time
       if File.exist?("#{CWD}/.vagrant/machines/#{machine}/virtualbox/action_provision")
         File.delete("#{CWD}/.vagrant/machines/#{machine}/virtualbox/action_provision")
       end
       provision_scripts = [
         "if [ ! -d /root/vagrant ];then mkdir /root/vagrant;fi;",
         %{cat > /root/vagrant/provision_settings.sh  << EOF
export CORPUSOPS_NUM="#{cfg['CORPUSOPS_NUM']}"
export CORPUSOPS_MACHINE="#{machine}"
export CORPUSOPS_MACHINE_NUM="#{machine_num}"
export CORPUSOPS_BASE_NAME="#{cfg['VIRTUALBOX_BASE_VM_NAME']}"
export CORPUSOPS_HOSTNAME="#{hostname}"
export CORPUSOPS_DOMAIN="#{cfg['DOMAIN']}"
export CORPUSOPS_FQDN="#{fqdn}"
export CORPUSOPS_VB_NAME="#{virtualbox_vm_name}"
export DNS_SERVERS="#{cfg['DNS_SERVERS']}"
export APT_MIRROR="#{cfg['APT_MIRROR']}"
export APT_PROXY="#{cfg['APT_PROXY']}"
export CORPUSOPS_AUTO_UPDATE="#{cfg['CORPUSOPS_AUTO_UPDATE']}"
export CORPUSOPS_HOST_OS="#{cfg['UNAME']}"
export FORCE_INSTALL="#{cfg['FORCE_INSTALL']}"
export FORCE_SYNC="#{cfg['FORCE_SYNC']}"
export SKIP_ROOTSSHKEYS_SYNC="#{cfg['SKIP_ROOTSSHKEYS_SYNC']}"
export SKIP_INSTALL="#{cfg['SKIP_INSTALL']}"
EOF},
         %{cat > /root/vagrant/provision_net.sh  << EOF
#!/usr/bin/env bash
. "/root/vagrant/provision_settings.sh" || exit 1
echo '#{hostname}' > /etc/hostname
hostname '#{hostname}'
sed -i -re "/::1 .*(localhost|#{fqdn}|#{hostname}).*/d" /etc/hosts
sed -i -re "/127.0.0.1 .*(localhost|#{fqdn}|#{hostname}).*/d" /etc/hosts
sed -i '1i::1 #{fqdn} #{hostname}' /etc/hosts
sed -i '1i127.0.0.1 #{fqdn} #{hostname}' /etc/hosts
echo "::1 #{fqdn} #{hostname}" >> /etc/hosts
echo "127.0.0.1 #{fqdn} #{hostname}" >> /etc/hosts
sed -i -re "/^nameserver /d" /etc/resolv.conf
for i in \\$DNS_SERVERS;do
    echo "nameserver \\$i" >>  /etc/resolv.conf
done
EOF},
         "chmod 700 /root/vagrant/provision_*.sh",
         "su -c /root/vagrant/provision_net.sh;",
         "su -l -c /srv/corpusops/corpusops.bootstrap/hacking/vagrant_provision_script.sh"]
       provision_script = provision_scripts.join("\n")
       sub.vm.provision :shell, :inline => provision_script
    end
  end
end

Vagrant.configure("2") do |config|
  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
    vb.customize ["modifyvm", :id, "--memory", cfg['MEMORY']]
    vb.customize ["modifyvm", :id, "--cpus", cfg['CPUS']]
    vb.customize ["modifyvm", :id, "--cpuexecutioncap", cfg['MAX_CPU_USAGE_PERCENT']]
    vb.customize ["modifyvm", :id, "--uartmode1"] + cfg['SERIAL']
  end
end
