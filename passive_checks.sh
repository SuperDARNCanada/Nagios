#!/bin/sh

NAGIOS_PLUGINS=/usr/local/nagios/lib/
NSCA=/usr/local/nagios/bin/send_nsca
HOSTNAME=hostname
#SERVER=sdcopy.usask.ca
SERVER=128.233.224.39
NSCA_CONFIG=/usr/local/nagios/etc/send_nsca.cfg

# Format for nsca:
# [hostname of sender]       [service name]  [status (0|1|2)]        [message]       [return char]
# 
# To send:
# send_nsca < "rkn.usask.ca       check_disk	0	Disks OK	\r\n"


# Declare an array of checks. The format is: "process name;check and arguments"
declare -a nsca_checks=("CPU Load;check_load -r -w 0.7,0.6,0.5 -c 0.9,0.8,0.7" \
"Process CPU check;check_procs -w 10 -c 20 --metric=CPU" \
"Drive usage;check_disk -w 10% -c 5% -p /data -p /home -p /" \
"Memory usage;check_swap -w 95% -c 80%" \
"Total users;check_users -w 4 -c 8" \
"dds server;check_procs -c 1: --argument-array='dds_server'")

# Loop through each check, parsing out the process name and the check with arguments
for check in "${nsca_checks[@]}"
do
	process_name=`echo ${check} | awk -F';' '{print $1}'`
	check_string=`echo ${check} | awk -F';' '{print $2}'`
	echo "Running: ${check_string}"
	output=`$NAGIOS_PLUGINS/$check_string`
	return_value=$?
	echo -e "${HOSTNAME}\t${process_name}\t${return_value}\t${output}" | $NSCA -H $SERVER -c $NSCA_CONFIG
done

exit
