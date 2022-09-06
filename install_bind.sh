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

if grep -Fxq "zone \"$zoneName\"{" /etc/bind/named.conf
then
	printf "\nZone already exist in /etc/bind/named.conf"
else
printf "zone \"$zoneName\"{\ntype master;\nfile \"/etc/bind/db.$zoneName\";\n};" >> /etc/bind/named.conf
fi

if test -f "/etc/bind/db.$zoneName"
then
	printf "\nFile /etc/bind/db.$zoneName exist. Remove ? (Y/n) :"
	read response
	if [ "$response" = "y" ] | [ "$response" = "Y" ]
	then
		rm "/etc/bind/db.$zoneName"
	fi
fi

email=""

while [ -z "$email" ]
do
echo "Enter admin's email address:"
read email
done
date=$(date +"%Y%m%d01")

printf "\$TTL 10800 \n@ IN SOA ns.$zoneName. $email.$zoneName. (\n$date\n6H\n1H\n5D\n1D )\n@ IN NS ns.$zoneName.\n@ IN MX 10 mail.$zoneName." >> /etc/bind/db.$zoneName
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

choice="4"

while [ "$choice" != "0" ]
do
echo "------------------------------------------------"
cat /etc/bind/db.$zoneName
printf "\n.0 Exit\t.1 A Record\n.2 MX Record (Under construction)\n"
echo "Adding other record: (Choose by typing the number): "
read choice
case $choice in 
	"0")
		exit
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

esac
done
echo "\n" >> /etc/bind/db.$zoneName
named-checkconf named.conf
named-checkzone $zoneName db.$zoneName
