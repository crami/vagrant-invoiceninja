# vagrant-invoiceninja
Vagrantfile for Invoice Ninja

This Project deploys a Vagrant VM with Invoice Ninja and all needed dependency.
It is based on a debian 8 template and runs nginx and mariadb.

Invoice-Ninja Source: https://www.invoiceninja.com/self-host/

Just install vagrant from your distributions repository or from https://www.vagrantup.com/
Additionaly you need virtual-box also from your distribution or from https://www.virtualbox.org/
Alternatively you may also use VMware Fusiom with the respective vagrant provider ;)

Make sure you have installed ```pwgen``` on your host.

Then clone this repository and do a 
<code>
vagrant up
</code>
Once the VM is created you can connect to https://localhost:8443

Enjoy
