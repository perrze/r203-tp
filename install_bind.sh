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
# Chekc if sudo or root
if [ "$EUID" -ne 0 ]
	then echo "Run as root or sudo"
	exit
fi
echo "bind9 will be installed"
apt install -y bind9

zoneName="";
# Asking for a zone name and if the user does not enter anything, it will keep asking until the user
# enters something.
while [ -z "$zoneName" ]
do
echo "Enter zone name: "
read zoneName
done
cp /etc/bind/named.conf.local /etc/bind/named.conf.local.bak
# Checking if the zone name already exist in the named.conf file. If it does, it will print a message.
# If it does not, it will add the zone to the named.conf file.
if grep -Fxq "zone \"$zoneName\"{" /etc/bind/named.conf.local
then
	printf "\nZone already exist in /etc/bind/named.conf.local"
else
printf "zone \"$zoneName\"{\ntype master;\nfile \"/etc/bind/db.$zoneName\";\n};" >> /etc/bind/named.conf.local
fi
passReconf="false"
# Checking if the db.$zoneName exist. If it does, it will ask the user if he wants to remove it.
# if user remove it, continue configuration
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

# Asking the user to enter an email address. If the user does not enter anything, it will keep asking
# until the user enters something.
while [ -z "$email" ]
do
	echo "Enter admin's email address:"
	read email
done
date=$(date +"%Y%m%d01")
# Add default configuration of DNS in db.zoneName (SOA and nameserver)
printf "\$TTL 10800 \n@ IN SOA ns.$zoneName. $email.$zoneName. (\n$date\n6H\n1H\n5D\n1D )\n@ IN NS ns.$zoneName." >> /etc/bind/db.$zoneName
nsIP=""
# Asking the user to enter an IPv4 address of ns server. If the user does not enter anything, it will keep asking
# until the user enters something.
while [ -z "$nsIP" ]
do
	echo "Enter IPv4 of NS server:"
	read nsIP
	# Check if enter correspond to an IPv4 address
	if [ $(check_ip "$nsIP") != "true" ]
       	then
        	nsIP=""
	fi
done
# Adding A record to db.zoneName
printf "\nns A $nsIP" >> /etc/bind/db.$zoneName

fi

choice="4"
# while user doesn't exit
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
	"1") # Adding a A record in db.$zoneName
	# Same scheme as adding IPv4 to nameserver
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
	"2") # Adding an MX record in db.$zoneName
		
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

# Check configuration of named.conf.local and db.$zoneName
named-checkconf /etc/bind/named.conf.local
named-checkzone $zoneName /etc/bind/db.$zoneName
# Save old conf
mv /etc/bind/named.conf.options /etc/bind/named.conf.options.bak
forward="8.8.8.8"
echo "Enter nameserver fowarders: (8.8.8.8)"
read forward
if [ -z "$forward" ] #  If not entering forwarder, adding 8.8.8.8 as default forwarder
then
	printf "options {\n directory \"/var/cache/bind\";\nforwarders{\n8.8.8.8 ;\n};\ndnssec-validation auto;\nauth-nxdomain no;\n};" >> /etc/bind/named.conf.options
else
	while [ $(check_ip "$forward") != "true" ]
	do
		echo "Enter nameserver fowarders: "
		read forward
	done
	printf "options {\n directory \"/var/cache/bind\";\nforwarders{\n$forward ;\n};\ndnssec-validation auto;\nauth-nxdomain no;\n};" >> /etc/bind/named.conf.options
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

echo "Reboot ? (y/N)"
read reb
if [ "$reboot" = "y" ] | [ "$reboot" = "Y" ]
then
reboot
else
echo "If not working, reboot"
fi
