#!/bin/sh

# Author : M Rahman
# Copyright (c) shadikur.com
# OS: CentOS 6.8 - 64 bit System
# Script follows here: 

#All the variables
bold=$(tput bold)
normal=$(tput sgr0)
green=$(tput setaf 2)

echo "${green}Adding 2GB of Swap Memory. ${normal}"
echo "${bold}Processing...Please wait.${normal}"
cd /var
touch swap.img
chmod 600 swap.img
dd if=/dev/zero of=/var/swap.img bs=2048k count=1000
echo  "${bold}${green}SWAP Processed Successfully${normal}"
mkswap /var/swap.img
swapon /var/swap.img
echo "/var/swap.img    none    swap    sw    0    0" >> /etc/fstab
sysctl -w vm.swappiness=30
echo  "${bold}${green}SWAP Memory added successfully.${normal}"
free -m
sleep 1

echo "${green}Removing Firewalld...${normal}"
sleep 1
yum remove firewalld -y


echo "Dsabling SELinux..."
sleep 1
sed -i 's/\(^SELINUX=\).*/\SELINUX=disabled/' /etc/sysconfig/selinux
sed -i 's/\(^SELINUX=\).*/\SELINUX=disabled/' /etc/selinux/config


echo "${green}Check for SEStatus.. ${normal}"
sestatus

echo "${green}Updating CentOS core ... ${normal}"
sleep 1
yum -y update


echo "${green}Installing Dev Tools... ${normal}"
sleep 1
yum -y groupinstall core base "Development Tools"


echo "${green}Adding Asterisk User... ${normal}"
sleep 1
adduser asterisk -m -c "Asterisk User"


echo "${green}Installing dependencies... ${normal}"
sleep 1
yum -y install lynx tftp-server unixODBC mysql-connector-odbc mysql-devel mysql-server\
  httpd ncurses-devel sendmail sendmail-cf sox newt-devel libxml2-devel libtiff-devel \
  audiofile-devel gtk2-devel subversion kernel-devel git crontabs cronie \
  cronie-anacron wget vim uuid-devel sqlite-devel net-tools gnutls-devel python-devel texinfo \
  libuuid-devel

echo "${green}Installing PHP 5.6 Repository... ${normal}"
sleep 1
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el6/latest.rpm

echo "${green}Installaing PHP is in progress ... ${normal}"
sleep 1
yum remove php* -y
yum install php56w php56w-pdo php56w-mysql php56w-mbstring php56w-pear php56w-process php56w-xml php56w-opcache php56w-ldap php56w-intl php56w-soap -y

echo "${green}Installing Nodjs ... ${normal}"
sleep 1
curl -sL https://rpm.nodesource.com/setup_8.x | bash -
yum install -y nodejs 

echo "${green}Setting Maria-DB on startup and starting now ... ${normal}"
sleep 1
chkconfig --level 345 mysqld on
service mysqld start

echo "${green}Setting Apache on startup and starting now ... ${normal}"
sleep 1
chkconfig --level 345 httpd on
service httpd start

echo "${green}Installing Console_Getopt ... ${normal}"
sleep 1
pear channel-update pear.php.net
pear install db-1.7.14

echo "${green}Downloading Asterisk Files ... ${normal}"
sleep 1
cd /usr/src
wget http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/libpri/libpri-current.tar.gz
wget -O jansson.tar.gz https://github.com/akheron/jansson/archive/v2.10.tar.gz
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-13-current.tar.gz

echo "${green}Compile and install jansson ... ${normal}"
sleep 1
cd /usr/src
tar vxfz jansson.tar.gz
rm -f jansson.tar.gz
cd jansson-*
autoreconf -i
./configure --libdir=/usr/lib64
make
make install

echo "${green}Compile and Install Asterisk ... ${normal}"
sleep 1
cd /usr/src
tar xvfz asterisk-13-current.tar.gz
rm -f asterisk-*-current.tar.gz
cd asterisk-*
contrib/scripts/install_prereq install
./configure --libdir=/usr/lib64 --with-pjproject-bundled
contrib/scripts/get_mp3_source.sh
make menuselect
make
make install
make config
ldconfig
chkconfig asterisk on

echo "${green}Setting up correct permission ... ${normal} "
sleep 1
chown asterisk. /var/run/asterisk
chown -R asterisk. /etc/asterisk
chown -R asterisk. /var/{lib,log,spool}/asterisk
chown -R asterisk. /usr/lib64/asterisk
chown -R asterisk. /var/www/

echo "${green}Installing and configuring enviroment for FreePBX ... ${normal} "
sleep 1
sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php.ini
sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/httpd/conf/httpd.conf
sed -i 's/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf
systemctl restart httpd.service

echo "${green}Download and install FreePBX ... ${normal} "
sleep 1
cd /usr/src
wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-13.0-latest.tgz
tar xfz freepbx-13.0-latest.tgz
rm -f freepbx-13.0-latest.tgz
cd freepbx
./start_asterisk start
./install -n

echo "${green}Adding a boot startup script  ... ${normal} "
sleep 1
echo "
[Unit]
Description=FreePBX VoIP Server
After=mariadb.service
 
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/sbin/fwconsole start -q
ExecStop=/usr/sbin/fwconsole stop -q
 
[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/freepbx.service
systemctl enable freepbx

echo "${green}Cleaning downloads ... ${normal}"
sleep 1
rm -rf /usr/src/asterisk*
rm -rf /usr/src/v*
chown -R root:root /var/spool/mqueue/
chmod 755 -R /var/spool/mqueue/
yum remove firewalld -y

chkconfig --level 0123456 iptables off
service iptables stop

echo "${green}${bold}Installation complete. Please visit the GUI through web browser. ${normal}"

