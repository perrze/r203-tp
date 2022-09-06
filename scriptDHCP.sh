#!/bin/bash


sudo apt update                                                     #mise à jour du paquet apt
sudo apt upgrade

if [ -d "/etc/dhcp" ]                                               #test pour savoir si le paquet isc-dhcp-server est installé
then                                                                #si oui, on supprime le paquet pour le réinstaller
apt-get remove --purge udhcpd
sudo apt-get install isc-dhcp-server
else                                                                #sinon on installe le paquet
sudo apt-get install isc-dhcp-server
fi


mv /etc/dhcp/dhcpd.conf /etc/dhcp/cpDhcpd.conf                      #on renomme le fichier de configuration initial et on en recréé un nouveau
touch /etc/dhcp/dhcpd.conf
                                                                                          #on demande à l'utilisateur toutes les informmations à avoir dans notre DHCP:
read -p "entrez le numéro de réseau distribué par le DHCP : " netNumber                   #numéro de réseau
read -p "entrez le masque de sous-réseau distribué par le DHCP : " netMask                #masque de sous-réseau
read -p "entrez la première adresse distribuée par le DHCP : " firstAddr                  #première adresse
read -p "entrez le dernière adresse distribuée par le DHCP : " lastAddr                   #dernière adresse
read -p "entrez le routeur par défaut distribué par le DHCP : " router                    #routeur
read -p "entrez l'adresse de broadcast distribuée par le DHCP : " broadcast               #adresse de broadcast du réseau
read -p "entrez le serveur DNS distribué par le DHCP : " dns                              #adresse du dns 
read -p "entrez la durée de bail par défaut : " defLease                                  #durée de bail par défaut
read -p "entrez la durée de bail maximale : " maxLease                                    #durée maximale de bail

echo "subnet $netNumber netmask $netMask {" >> /etc/dhcp/dhcpd.conf                       #on ajoute toutes les informations dans le fichier de configuration de notre serveur
echo "range $firstAddr $lastAddr ;" >> /etc/dhcp/dhcpd.conf
echo "option routers $router ;" >> /etc/dhcp/dhcpd.conf
echo "option broadcast-address $broadcast ;" >> /etc/dhcp/dhcpd.conf
echo "option domain-name-servers $dns ;" >> /etc/dhcp/dhcpd.conf
echo "default-lease-time $defLease ;" >> /etc/dhcp/dhcpd.conf
echo "max-lease-time $maxLease ;" >> /etc/dhcp/dhcpd.conf
echo "}" >> /etc/dhcp/dhcpd.conf

read -p "rentrez le nom de l'interface :" int                                        #on demande l'interface sur laquelle fonctionnera le serveur
echo "INTERFACESv4 = $int" >> /etc/default/isc-dhcp-server                           #on ajoute cette interface dans le fichier /etc/default/isc-dhcp-server

sudo service isc-dhcp-server restart                                                 #on redémare le service pour appliquer les changements
