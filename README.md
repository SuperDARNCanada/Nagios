# Nagios
Nagios monitoring configuration files for SuperDARN hardware and networks.

## Installation

### Nagios Core
Nagios installation instructions can be found [here:](https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/4/en/quickstart.html)

Here the steps are reproduced for OpenSuSe 15.1:
 * sudo zypper --non-interactive install autoconf gcc glibc make wget unzip apache2 apache2-utils php7 apache2-mod_php7 gd gd-devel
 * reboot
 * (following as root)
 * cd /tmp
 * wget -O nagioscore.tar.gz https://github.com/NagiosEnterprises/nagioscore/archive/nagios-4.4.5.tar.gz
 * tar xzf nagioscore.tar.gz
 * cd nagioscore-nagios-4.4.5
 * ./configure --with-httpd-conf=//etc/apache2/vhosts.d
 * make all -j8
 * sudo make install-groups-users
 * sudo /usr/sbin/usermod -a -G nagios wwwrun
 * make install 
 * make install-daemoninit
 * make install-commandmode
 * make install-config
 * sudo make install-webconf
 * sudo /usr/sbin/a2enmod rewrite
 * sudo /usr/sbin/a2enmod cgi
 * sudo /usr/sbin/a2enmod version
 * sudo /usr/sbin/a2enmod php7
 * sudo systemctl enable apache2.service
 * htpasswd2 -c /usr/local/nagios/etc/htpasswd.users nagiosadmin
 * systemctl start apache2.service
 * systemctl start nagios.service
 
 ### NRPE 
 
Instructions for installing and using NRPE can be found in [this](https://github.com/SuperDARNCanada/Nagios/blob/master/NRPE.pdf) PDF file. To properly use NRPE, you'll need to specify allowed hosts in the nrpe.cfg file. I've used hostnames here, but they can be IP addresses too.

For convenience, here are the steps required to install NRPE on the server:
 * wget https://github.com/NagiosEnterprises/nrpe/rel;eases/download/nrpe-3.2.1/nrpe-3.2.1.tar.gz
 * tar xvf nrpe-3.2.1.tar.gz
 * cd nrpe-3.2.1/
 * ./configure
 * make check_nrpe
 * sudo make install-plugin
 
 Now to verify that it's working properly:
 * /usr/local/nagios/lib/check_nrpe -H sasborealis.usask.ca
 This should return the version of NRPE running, without a timeout.

### Nagios Plugins

Instructions for installing Plugins are found in the Nagios installation instructions above, but they are reproduced here for convenience:

 * cd /tmp
 * wget --no-check-certificate -O nagios-plugins.tar.gz https://github.com/nagios-plugins/nagios-plugins/archive/release-2.2.1.tar.gz
 * tar zxf nagios-plugins.tar.gz
 * cd nagios-plugins-release-2.2.1/
 * sudo ./tools/setup
 * sudo ./configure
 * sudo make
 * sudo make install

Now you should have the appropriate plugins located in /usr/local/nagios/lib/ or wherever you've defined the nagios location to be.

### nrpe installation on client
You may need to install openssl library before configuring nrpe. On openSuSE 15.1 that is accomplished by:

* sudo zypper in libopenssl-1\_1-devel


The nrpe daemon and check\_nrpe binary are installed by downloading the nrpe source files, untarring them, configuring, making and installing. On OpenSUSE 15.1 the following steps make this work:


* tar xvf nrpe-3.2.1.tar.gz
* cd nrpe-3.2.1
* ./configure --enable-command-args
* make all -j8
* sudo make install-groups-users
* sudo make install
* sudo make install-inetd
* sudo make install-init

Then you can install the configuration file from this git repository (default location for this is to be placed is /usr/local/nagios/etc/)

* sudo mkdir /usr/local/nagios/etc/
* sudo chown nagios:nagios /usr/local/nagios/etc/
* sudo cp -v [path to git repo]/configs/remote\_configs/nrpe.cfg /usr/local/nagios/etc/

Now, to run it:

* sudo systemctl enable nrpe.service
* sudo systemctl start nrpe.service
* sudo systemctl status nrpe.service

And it should hopefully not have any errors.

If you remake the nrpe daemon, after changing the configuration for example, you will need to execute the following after re-installing it:

* sudo systemctl daemon-reload

### nagios-plugins installation on client
These are the official plugins of the nagios group, and are installed by default in the /usr/local/nagios/lib/ directory.

* tar xvf nagios-plugins-2.2.1.tar.gz
* cd nagios-plugins-2.2.1
* ./configure 
* make -j8
* sudo make install

If you run into problems with configure failing on mysql, then you can use the configure flag: --without-mysql

### Custom plugin installation on client
If you've written your own plugin (such as the *check_borealis* python script in the *plugins* directory) then you simply need to copy it into the nagios lib path (default */usr/local/nagios/lib*)

### nsca installation on client
In order for some of the SuperDARN machines to actually take advantage of nagios, they need to push their own checks to the nagios server, due to being behind routers or firewalls.
The nsca package allows passive checks, which is when a client of the nagios server initiates the check instead of the nagios server reaching out to the client to check on things.

* tar xvf nsca-2.9.2.tar.gz
* cd nsca-2.9.2
* ./configure
* make all -j8
* sudo cp -v sample-config/send\_nsca.cfg /usr/local/nagios/etc/
* sudo cp -v src/send\_nsca /usr/local/nagios/bin/

Now to do passive checks from the client:

* send\_nsca < [hostname of sender]	[service name]	[status (0|1|2)]	[message]	[return char]

### nsca installation on server

#### Dependencies
You'll need to install the following if you want cryptography enabled in nsca:
 * https://sourceforge.net/projects/mhash/files/mhash/
 * ftp://mcrypt.hellug.gr/pub/crypto/mcrypt/libmcrypt
 * https://sourceforge.net/projects/mcrypt/files/MCrypt/
 
#### NSCA

The nsca daemon needs to run on the server for passive checks via send\_nsca from clients to work

* tar xvf nsca-2.9.2.tar.gz
* cd nsca-2.9.2
* ./configure
* make all -j8
* sudo cp -v nsca /usr/local/nagios/bin/
* sudo cp -v sample-config/nsca.cfg /usr/local/nagios/etc/

A crontab entry starts nsca upon boot on the nagios server machine, a line like the following works:

* @reboot /usr/local/nagios/bin/nsca -c /usr/local/nagios/etc/nsca.cfg

The nsca daemon listens for incoming packets that look like so, with tab characters between items:
[hostname of sender]	[service name]	[status (0|1|2)]	[message]	[return char]

## Usage notes

### How to deal with hosts behind a router, with port forwarding
Many devices are going to be behind a router, with the potential for port forwarding so that services
on those hosts can be accessed. There are several ways around this for checking on the host
or the services.

For hosts, you can add custom variables to the definitions like so for the _PORT and _NRPE_PORT:
define host {
        use                     linux-server
        host_name               bcd
        address                 104.160.221.191
        _PORT                   50822
        _NRPE_PORT              50866
        check_command           check_ssh_custom_port
}

Then  these variables can be used in the definition of commands like so for using special ports for checking http and nrpe:
define command {
        command_name    check_nrpe_custom_port
        command_line    $USER1$/check_nrpe -H $HOSTADDRESS$ -p $_HOSTNRPE_PORT$ -c $ARG1$ $ARG2$
}
define command {

    command_name    check_http_custom_port
    command_line    $USER1$/check_http -I $HOSTADDRESS$ -p $_HOSTPORT$ $ARG1$
}


Please see these forum posts: 
https://support.nagios.com/forum/viewtopic.php?f=7&t=5087
https://forums.meulie.net/t/problem-pinging-hosts-with-ip-address-through-a-port/4068

### Updating server configuration

On the Nagios server, any time you make a change to a configuration file you must reload the nagios service:

* sudo systemctl restart nagios.service

### Change the nagios web interface password

Log into the web interface on the nagios server and log in via the nagiosadmin password
To change the password for nagiosadmin:

* sudo htpasswd /usr/local/nagios/etc/htpasswd.users nagiosadmin

### Basic troubleshooting

If you have any issues with things not running make sure of the following:
1. nagios:nagios are the user and group that own the binaries for nagios and permissions are appropriate
2. The environment variables that are accessible by nagios are limited (they are those of the nagios user)
3. check the /var/log/messages file for error messages
4. You've restarted the daemons via sudo systemctl restart nrpe.service|nagios.service
 
