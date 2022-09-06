#!/bin/bash


sudo apt update
sudo apt upgrade

if [ -d "/etc/dhcp" ]
then 
apt-get remove --purge udhcpd
#else
#ip = $(ip -f inet addr show ens192 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p')
#if [ -z "$ip" ]
#then
#read -p echo "entrez le nom de l'interface :" int
#sudo dhclient ens192 $int
sudo apt-get install isc-dhcp-server
#sudo ip addr flush dev $int
else
sudo apt-get install isc-dhcp-server
#sudo ip addr flush dev $int
#fi
fi

if [ -d "/home/user/copie_fichiers_conf" ]
then 
mv /etc/dhcp/dhcpd.conf /home/user/copie_fichiers_conf/cpDhcpd.conf
touch /etc/dhcp/dhcpd.conf
else
mkdir /home/user/copie_fichiers_conf
mv /etc/dhcp/dhcpd.conf /home/user/copie_fichiers_conf/cpDhcpd.conf
mv /etc/default/isc-dhcp-server /home/user/copie_fichier_conf/cpDefault_isc-dhcp-server
touch /etc/dhcp/dhcpd.conf
fi

read -p echo "donnez l'adresse ip à votre serveur (adresse de la machine) : " ipServ
read -p echo "donnez le masque de sous réseau à attribuer à votre serveur (au format préfixe): " netMask1
ip addr add $ipServ"/"$netMask dev int

read -p "entrez le numéro de réseau distribué par le DHCP : " netNumber
read -p "entrez le masque de sous-réseau distribué par le DHCP : " netMask
read -p "entrez la première adresse distribuée par le DHCP : " firstAddr
read -p "entrez le dernière adresse distribuée par le DHCP : " lastAddr
read -p "entrez le routeur par défaut distribué par le DHCP : " router
read -p "entrez l'adresse de broadcast distribuée par le DHCP : " broadcast
read -p "entrez le serveur DNS distribué par le DHCP : " dns
read -p "entrez la durée de bail par défaut : " defLease
read -p "entrez la durée de bail maximale : " maxLease

echo "subnet $netNumber netmask $netMask {" >> /etc/dhcp/dhcpd.conf
echo "range $firstAddr $lastAddr ;" >> /etc/dhcp/dhcpd.conf
echo "option routers $router ;" >> /etc/dhcp/dhcpd.conf
echo "option broadcast-address $broadcast ;" >> /etc/dhcp/dhcpd.conf
echo "option domain-name-servers $dns ;" >> /etc/dhcp/dhcpd.conf
echo "default-lease-time $defLease ;" >> /etc/dhcp/dhcpd.conf
echo "max-lease-time $maxLease ;" >> /etc/dhcp/dhcpd.conf
echo "}" >> /etc/dhcp/dhcpd.conf


echo "INTERFACESv4 = $int" >> /etc/default/isc-dhcp-server

sudo service isc-dhcp-server restart
