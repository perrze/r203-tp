#!/bin/bash
function check_ip(){
	if [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  		echo "true"
	else
  		echo "false"
	fi
}

echo "------------------------------------------------"
echo "bind9 install script for debian"
if [ "$EUID" -ne 0 ]
	then echo "Run as root or sudo"
	exit
fi
echo "bind9 will be installed"
apt install -y bind9

zoneName="";
while [ -z "$zoneName" ]
do
echo "Enter zone name: "
read zoneName
done
cp /etc/bind/named.conf /etc/bind/named.conf.bak
if grep -Fxq "zone \"$zoneName\"{" /etc/bind/named.conf
then
	printf "\nZone already exist in /etc/bind/named.conf"
else
printf "zone \"$zoneName\"{\ntype master;\nfile \"/etc/bind/db.$zoneName\";\n};" >> /etc/bind/named.conf
fi
passReconf="false"
if test -f "/etc/bind/db.$zoneName"
then
	printf "\nFile /etc/bind/db.$zoneName exist. Remove ? (y/N) :"
	read response
	if [ "$response" = "y" ] | [ "$response" = "Y" ]
	then
		rm "/etc/bind/db.$zoneName"
	else
	passReconf="true"
	fi
fi

if [ "$passReconf" = "false" ]
then
email=""

while [ -z "$email" ]
do
	echo "Enter admin's email address:"
	read email
done
date=$(date +"%Y%m%d01")

printf "\$TTL 10800 \n@ IN SOA ns.$zoneName. $email.$zoneName. (\n$date\n6H\n1H\n5D\n1D )\n@ IN NS ns.$zoneName." >> /etc/bind/db.$zoneName
nsIP=""
while [ -z "$nsIP" ]
do
	echo "Enter IPv4 of NS server:"
	read nsIP
	if [ $(check_ip "$nsIP") != "true" ]
       	then
        	nsIP=""
	fi
done

printf "\nns A $nsIP" >> /etc/bind/db.$zoneName

fi

choice="4"

while [ "$choice" != "0" ]
do
echo "------------------------------------------------"
cat /etc/bind/db.$zoneName
printf "\n.0 Exit\t.1 A Record\n.2 MX Record\n"
echo "Adding other record: (Choose by typing the number): "
read choice
case $choice in 
	"0")
		choice="0"
		;;
	"1")
		name=""
		while [ -z "$name" ]
		do
			echo "Enter machine name for the A record:"
			read name
		done
		ip=""
		while [ -z "$ip" ]
		do
			echo "Enter IPv4 for the A record:"
			read ip
			if [ $(check_ip "$ip") != "true" ]
			then
				$ip=""
			fi
		done
		printf "\n$name A $ip" >> /etc/bind/db.$zoneName
		;;
	"2")
		
                comp=""
                while [ -z "$comp" ]
                do
	                echo "Enter machine name for the MX record:"
        	        read comp
                done
                prio=""
                while [ -z "$prio" ]
                do
	                echo "Enter priority for the MX record :"
        	        read prio
                	if [[ $prio =~ ^[0-9]+$ ]]
                	then
                		$prio=""
                	fi
                done
		printf "\n@ IN MX $prio $comp.$zoneName." >> /etc/bind/db.$zoneName
                ip=""
                while [ -z "$ip" ]
                do
                	echo "Enter IPv4 for the mail server A record:"
                	read ip
                	if [ $(check_ip "$ip") != "true" ]
                	then
                		$ip=""
                	fi
                done
                printf "\n$comp A $ip" >> /etc/bind/db.$zoneName

esac
done
printf " \n"
named-checkconf /etc/bind/named.conf
named-checkzone $zoneName /etc/bind/db.$zoneName

forward="8.8.8.8"
echo "Enter nameserver fowarders: (8.8.8.8)"
read forward
if [ -z "$forward" ]
then
	printf "forwarders{\n8.8.8.8 ;\n};" >> /etc/bind/named.conf.options
else
	while [ $(check_ip "$forward") != "true" ]
	do
		echo "Enter nameserver fowarders: "
		read forward
	done
	printf "forwarders{\n$forward ;\n};" >> /etc/bind/named.conf.options
fi
echo "Enable bind9 on startup ? (y/N)"
read response
        if [ "$response" = "y" ] | [ "$response" = "Y" ]
        then
                systemctl enable bind9
        fi
        exit
        fi
echo "Starting bind9..."
systemctl start bind9
echo systemctl status bind9
