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

## vagrant-moloch
List of files and their descriptions.
1. vagrant-moloch/**Vagrantfile**
By default in this config file (line 23) is config.vm.synced_folder disabled: true. After first run (vagrant up), change:
> config.vm.synced_folder ".", "/vagrant", owner: "vagrant", group: "vagrant", disabled: **true**

TO

> config.vm.synced_folder ".", "/vagrant", owner: "vagrant", group: "vagrant", disabled: **false**

2. **vagrant-moloch**/script/**check_box.sh**
This script check if you have installed vagrant box **debian/stretch64**. If not, this script just install needed box.

3. **vagrant-moloch**/script/**bootstrap-debian-moloch.sh**
This main script, which install latest VirtualBox Guest Additions for Linux, Open JDK 8, NodeSource Node.js 8.x, Elasticsearch 6.4.2 and Moloch 1.7.1. and create bash script **pcap-upload.sh** located in folder **/etc/cron.d/pcap-upload.sh**. His role is lookup on folder **/vagrant/share/pcap/new** and when you put pcap file on this place, just run moloch-capture to import Elasticsearch database. Script pcap-upload.sh running every 1 minute and log his activity to syslog.

For example:

> sudo grep -i pcap /var/log/syslog

Output:

<pre>
Feb 11 11:51:01 vagrant-moloch CRON[906]: (root) CMD (/etc/cron.d/pcap-upload.sh)

Feb 11 11:51:01 vagrant-moloch pcap-upload.sh: PCAP-UPLOAD: Processing file /vagrant/share/pcap/ready/7357d64315022934708dfe07d5be1ab2.pcap.

Feb 11 11:51:08 vagrant-moloch pcap-upload.sh: PCAP-UPLOAD: File /vagrant/share/pcap/ready/7357d64315022934708dfe07d5be1ab2.pcap is ready.
</pre>
<pre>
Default login to Vagrant Moloch:
username: admin
password: admin
</pre>

## vagrant-minemeld
List of files and their descriptions.
1. vagrant-minemeld/**Vagrantfile**
By default in this config file (line 22) is config.vm.synced_folder disabled: true. After first run (vagrant up), change:
> config.vm.synced_folder ".", "/vagrant", owner: "vagrant", group: "vagrant", disabled: **true**

TO

> config.vm.synced_folder ".", "/vagrant", owner: "vagrant", group: "vagrant", disabled: **false**

2. **vagrant-minemeld**/script/**check_box.sh**
This script check if you have installed vagrant box **debian/stretch64**. If not, this script just install needed box.

3. **vagrant-minemeld**/script/**bootstrap-debian-minemeld.sh**
This main script, which install stable MineMeld from source code which use the Ansible playbook.
[MineMeld User's Guide] (https://github.com/PaloAltoNetworks/minemeld/wiki/User's-Guide)

<pre>
Default login to Vagrant Minemeld:
username: admin
password: minemeld
</pre>
