# vagrant
All my Vagrant VMs

## vagrant-splunk
Before starting this vagrant you have to download splunk yourself (*.deb) and save it to folder **packages**. Then you have to made some changes in Vagrantfile. For example if you save splunk package as splunk-7.3.deb, then do this:

FROM (Vagrantfile lines:10,11,12)
<pre>
if File.exists?(File.expand_path("./packages/splunk-7.3.0.deb"))
    config.vm.provision "file", source: "./packages/splunk-7.3.0.deb", destination: "/tmp/splunk-7.3.0.deb"
end
</pre>
TO
<pre>
if File.exists?(File.expand_path("./packages/splunk-7.3.deb"))
    config.vm.provision "file", source: "./packages/splunk-7.3.deb", destination: "/tmp/splunk-7.3.deb"
end
</pre>

and

FROM (Vagrantfile line 19)
<pre>
:package => "splunk-7.3.0.deb"
</pre>
TO
<pre>
:package => "splunk-7.3.deb"
</pre>

List of files and their descriptions.
1. vagrant-splunk/**Vagrantfile**
By default in this config file (line 27) is config.vm.synced_folder disabled: true. After first run (vagrant up), change:
> config.vm.synced_folder ".", "/vagrant", owner: "vagrant", group: "vagrant", disabled: **true**

TO

> config.vm.synced_folder ".", "/vagrant", owner: "vagrant", group: "vagrant", disabled: **false**

2. **vagrant-splunk**/script/**check_box.sh**
This script check if you have installed vagrant box **debian/stretch64**. If not, this script just install needed box.

3. **vagrant-splunk**/script/**bootstrap-debian-base.sh**
This main script, which install latest VirtualBox Guest Additions for Linux and do some basic configuration of debian.

4. **vagrant-splunk**/script/**bootstrap-debian-splunk.sh**
This script install Splunk, create Administrator user and enable starting Splunk on boot.

<pre>
Login to Vagrant Splunk:
https://127.0.0.1:8000
username: admin
password: Password123
</pre>
