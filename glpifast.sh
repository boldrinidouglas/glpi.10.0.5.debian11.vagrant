#!/bin/bash
echo "-------------------------------------------------------------------------------------"
echo "---------------------------------Debian 10 and GLPI-10.0.5----------------------------"
echo "-------------------------------------------------------------------------------------"

echo "Passo 1: Declarando variáveis"
set 
glpiversion='10.0.5'
phpversion='8.1' 
db='glpi'
pswd='glpipass'
userdb='glpi'
srv='localhost'
glpiacesso="192.168.1.10"

echo "Passo 1: Atualizando Debian 11"
sudo apt update

echo "Passo 2: Ajustando timezone!"
sudo apt purge -y ntp
sudo apt install -y openntpd
sudo service openntpd stop
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
sudo cat > /home/vagrant/tzdata.txt <<EOF
tzdata tzdata/Areas select America
tzdata tzdata/Zones/America select Sao Paulo
locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8
locales locales/default_environment_locale select en_US.UTF-8
EOF
sudo debconf-set-selections /home/vagrant/tzdata.txt
sudo echo "servers pool.ntp.br" > /etc/openntpd/ntpd.conf

echo "Passo 3: Instalando pacotes de manipulação de arquivos"
sudo apt install -y xz-utils bzip2 unzip curl

echo "Passo 4: Ajustando Versão do PHP"
sudo apt remove -y --purge php*
sudo apt install -y lsb-release ca-certificates apt-transport-https software-properties-common gnupg2   
sudo locale-gen en_US.UTF-8
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/sury-php.list
sudo wget -qO - https://packages.sury.org/php/apt.gpg | sudo gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/debian-php-8.gpg --import
sudo chmod 644 /etc/apt/trusted.gpg.d/debian-php-8.gpg
sudo apt update && sudo apt upgrade -y
sudo apt install -y php$phpversion libapache2-mod-php php-{soap,cas,apcu,cli,common,curl,gd,imap,ldap,mysql,xmlrpc,xml,mbstring,bcmath,intl,zip,bz2}


echo "Passo 5: Instalar Servidor Web e criar arquivo de configuração"
sudo apt install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
sudo cat > /etc/apache2/conf-available/glpi.conf <<EOF
<VirtualHost *:80>
DocumentRoot "/var/www/html/glpi/"
ServerName glpi
</VirtualHost>

<Directory /usr/share/glpi/>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
</Directory>
EOF

sudo systemctl reload apache2
sudo a2enconf glpi.conf

echo "Passo 6: Baixar, instalar e copiar para o diretorio a instalação do GLPI"
wget -O- https://github.com/glpi-project/glpi/releases/download/$glpiversion/glpi-$glpiversion.tgz | tar -zxv -C /var/www/html/

echo "Passo 7: Ajustar permissões de arquivos"
sudo chown www-data. /var/www/html/glpi -Rf
sudo find /var/www/html/glpi -type d -exec chmod 755 {} \;
find /var/www/html/glpi -type f -exec chmod 644 {} \;

echo "Passo 8: Instalar e iniciar MariaDB"
sudo apt install -y mariadb-server
sudo systemctl start mariadb
sudo systemctl enable mariadb

echo "Passo 9: Configurando o usuário root no MariaDB"
mysql -u root <<-EOF
DROP USER 'root'@'localhost';
CREATE USER 'root'@'%' IDENTIFIED BY '$pswd';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

echo "Passo 10: Acessando, criando e permissionando o banco GLPI"
mysql --user=root --password=glpipass --execute="CREATE DATABASE IF NOT EXISTS $db character set utf8";
mysql --user=root --password=glpipass --execute="CREATE USER $userdb@$srv IDENTIFIED BY '$pswd'";
mysql --user=root --password=glpipass --execute="GRANT USAGE ON *.* TO $userdb@$srv IDENTIFIED BY '$pswd'";
mysql --user=root --password=glpipass --execute="GRANT ALL PRIVILEGES ON $db.* TO $userdb@$srv";
mysql --user=root --password=glpipass --execute="FLUSH PRIVILEGES";

echo "Passo 11: Habilitando suporte ao timezone no MySQL/Mariadb. Permitindo acesso do usuário ao TimeZone"
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql --user=root --password=$pswd mysql
mysql --user=root --password=$pswd --execute="GRANT SELECT ON mysql.time_zone_name TO $userdb@$srv";
mysql --user=root --password=$pswd --execute="FLUSH PRIVILEGES";


echo "Passo 12: Habilitando NFTables do Debian e configurando serviço http"
sudo cat << EOF > /etc/nftables.rules
flush ruleset

table firewall {
  chain incoming {
    type filter hook input priority 0; policy drop;

    # established/related connections
    ct state established,related accept

    # loopback interface
    iifname lo accept

    # icmp
    icmp type echo-request accept

    # open tcp ports: sshd (22), httpd (80)
    tcp dport {ssh, http} accept
  }
}

table ip6 firewall {
  chain incoming {
    type filter hook input priority 0; policy drop;

    # established/related connections
    ct state established,related accept

    # invalid connections
    ct state invalid drop

    # loopback interface
    iifname lo accept

    # icmp
    # routers may also want: mld-listener-query, nd-router-solicit
    icmpv6 type {echo-request,nd-neighbor-solicit} accept

    # open tcp ports: sshd (22), httpd (80)
    tcp dport {ssh, http} accept
  }
}
EOF
sudo chmod u+x /etc/nftables.rules
sudo nft list ruleset > /etc/nftables.rules
sudo nft flush ruleset
sudo nft -f /etc/nftables.rules

echo "Parabéns. A instalação foi finalizada------------------------------------------------"
echo "-------------------------------------------------------------------------------------"
echo "Acesse http://$glpiacesso para finalizar a configuração" 
echo "SQL server(MariaDB) : $srv"
echo "Usuário SQL : $userdb"
echo "Senha SQL : $pswd"
echo "Select Database : $db"
echo "Acesse: www.boldrini.tech"
echo "-------------------------------------------------------------------------------------"
echo "-------------------------------------------------------------------------------------"