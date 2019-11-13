# Nagios
Nagios monitoring configuration files for SuperDARN hardware and networks.

## Installation
Nagios installation instructions can be found [here:](https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/4/en/quickstart.html)

Instructions for installing and using NRPE can be found in [this](https://github.com/SuperDARNCanada/Nagios/blob/master/NRPE.pdf) PDF file. To properly use NRPE, you'll need to specify allowed hosts in the nrpe.cfg file. I've used hostnames here, but they can be IP addresses too.

### nrpe installation on client
You may need to install openssl library before configuring nrpe. On openSuSE 15.1 that is accomplished by:

'''bash
sudo zypper in libopenssl-1\_1-devel
'''

The nrpe daemon and check\_nrpe binary are installed by downloading the nrpe source files, untarring them, configuring, making and installing. On OpenSUSE 15.1 the following steps make this work:

'''bash
tar xvf nrpe-3.2.1.tar.gz
cd nrpe-3.2.1
./configure --enable-command-args
make all -j8
sudo make install-groups-users
sudo make install
sudo make install-inetd
sudo make install-init
'''

Then you can install the configuration file from this git repository (default location for this is to be placed is /usr/local/nagios/etc/)

'''bash
sudo mkdir /usr/local/nagios/etc/
sudo chown nagios:nagios /usr/local/nagios/etc/
sudo cp -v [path to git repo]/configs/remote\_configs/nrpe.cfg /usr/local/nagios/etc/
'''

Now, to run it:

'''bash
sudo systemctl enable nrpe.service
sudo systemctl start nrpe.service
sudo systemctl status nrpe.service
'''

And it should hopefully not have any errors.

If you remake the nrpe daemon, after changing the configuration for example, you will need to execute the following after re-installing it:

'''bash
sudo systemctl daemon-reload
'''

### nagios-plugins installation on client
These are the official plugins of the nagios group, and are installed by default in the /usr/local/nagios/lib/ directory.

'''bash
tar xvf nagios-plugins-2.2.1.tar.gz
cd nagios-plugins-2.2.1
./configure 
make -j8
sudo make install
'''

If you run into problems with configure failing on mysql, then you can use the configure flag: --without-mysql

### Custom plugin installation on client
If you've written your own plugin (such as the *check_borealis* python script in the *plugins* directory) then you simply need to copy it into the nagios lib path (default */usr/local/nagios/lib*)

### nsca installation on client
In order for some of the SuperDARN machines to actually take advantage of nagios, they need to push their own checks to the nagios server, due to being behind routers or firewalls.
The nsca package allows passive checks, which is when a client of the nagios server initiates the check instead of the nagios server reaching out to the client to check on things.

'''bash
tar xvf nsca-2.9.2.tar.gz
cd nsca-2.9.2
./configure
make all -j8
sudo cp -v sample-config/send\_nsca.cfg /usr/local/nagios/etc/
sudo cp -v src/send\_nsca /usr/local/nagios/bin/
'''

Now to do passive checks from the client:

'''bash
send\_nsca < [hostname of sender]	[service name]	[status (0|1|2)]	[message]	[return char]
'''

### nsca installation on server
The nsca daemon needs to run on the server for passive checks via send\_nsca from clients to work

'''bash
tar xvf nsca-2.9.2.tar.gz
cd nsca-2.9.2
./configure
make all -j8
sudo cp -v nsca /usr/local/nagios/bin/
sudo cp -v sample-config/nsca.cfg /usr/local/nagios/etc/
'''

A crontab entry starts nsca upon boot on the nagios server machine, a line like the following works:

'''bash
@reboot /usr/local/nagios/bin/nsca -c /usr/local/nagios/etc/nsca.cfg
'''

The nsca daemon listens for incoming packets that look like so, with tab characters between items:
[hostname of sender]	[service name]	[status (0|1|2)]	[message]	[return char]


## Usage notes

On the Nagios server, any time you make a change to a configuration file you must reload the nagios service:

'''bash
sudo systemctl restart nagios.service
'''

Log into the web interface on the nagios server and log in via the nagiosadmin password
To change the password for nagiosadmin:

'''bash
sudo htpasswd /usr/local/nagios/etc/htpasswd.users nagiosadmin
'''


If you have any issues with things not running make sure of the following:
1. nagios:nagios are the user and group that own the binaries for nagios and permissions are appropriate
2. The environment variables that are accessible by nagios are limited (they are those of the nagios user)
3. check the /var/log/messages file for error messages
4. You've restarted the daemons via sudo systemctl restart nrpe.service|nagios.service
 
