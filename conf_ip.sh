#!/bin/bash
function check_ip(){
	if [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  		echo "true"
	else
  		echo "false"
	fi
}
echo "----------------------------"
echo "This script will change ip configuration in /etc/network/interfaces"
if [ "$EUID" -ne 0 ]
	then echo "Run as root or sudo"
	exit
fi
echo "Saving /etc/network/interfaces..."
mv /etc/network/interfaces /etc/network/interfaces.bak
echo "Auto configuring loopback interface"
printf "auto lo\niface lo inet loopback\n" >> /etc/network/interfaces
echo ip link ls
echo "Select interface from above : "
read interface
printf "auto $interface\n" >> /etc/network/interfaces
echo "Choose:"
echo "1. dhcp\t2. static"
read type
if [ "$type" = "1" ];then
    printf "iface $interface inet dhcp\n" >> /etc/network/interfaces
    echo "Network configured for $interface with dhcp"
    echo "Exiting..."
    exit

printf "iface $interface inet static\n" >> /etc/network/interfaces

ip=""
while [ -z "$ip" ]
do
	echo "Enter ip address:"
    read ip
	# Check if enter correspond to an IPv4 address
	if [ $(check_ip "$ip") != "true" ]
       	then
        	ip=""
	fi
done
printf "address $ip\n" >> /etc/network/interfaces

mask=""
while [ -z "$mask" ]
do
	echo "Enter netmask:"
    read mask
	# Check if enter correspond to an IPv4 address
	if [ $(check_ip "$mask") != "true" ]
       	then
        	mask=""
	fi
done
printf "netmask $mask\n" >> /etc/network/interfaces

gateway=""
while [ -z "$gateway" ]
do
	echo "Enter gateway address:"
    read gateway
	# Check if enter correspond to an IPv4 address
	if [ $(check_ip "$gateway") != "true" ]
       	then
        	gateway=""
	fi
done
printf "gateway $gateway\n" >> /etc/network/interfaces

dns=""
while [ -z "$dns" ]
do
	echo "Enter dns address:"
    read dns
	# Check if enter correspond to an IPv4 address
	if [ $(check_ip "$dns") != "true" ]
       	then
        	dns=""
	fi
done
printf "dns-nameservers $dns\n" >> /etc/network/interfaces
