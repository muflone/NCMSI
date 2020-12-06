#!/bin/bash
##
#     Project: NCMSI (Nextcloud Multiple Steps Install)
# Description: This bash script installs Nextcloud in a remote system
#      Author: Fabio Castelli (Muflone) <muflone@muflone.com>
#   Copyright: 2020 Fabio Castelli
#     License: GPL-3+
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.
##
# The execution process is made of multiple steps:
#     1) setup the local SSH connection to the remote system
#     2) install and setup the services
##

# Set input arguments
_HOSTNAME="${1}"
_MYSQL_ROOT_PASSWORD="${2}"
_MYSQL_NEXTCLOUD_PASSWORD="${3}"
_SSL_CERTIFICATE_FILE="${4}"
_SSL_CERTIFICATE_KEY="${5}"
_DHPARAM_FILE="${6}"
_STEP="${7}"

do_instructions()
{
    # Show instructions
    echo "Install Nextcloud in the remote system"
    echo "usage: $0 <hostname> <mysql root password> <mysql nextcloud password> <ssl certificate file> <ssl certificate key> <dhparm file> [step]"
    echo "step arguments could be 0-5 like the following:"
    echo "  0  Show this help"
    echo "  1  Connect to the remote system and go to the next step"
    echo "  2  Install and setup mariadb, nginx and nextcloud"
    exit 2
}

do_usage()
{
    # Show command usage
    echo not enough arguments:
    do_instructions
    exit 1
}

do_remote_command()
{
    # Connect to the remote system using root user
    set +o pipefail
    ssh -o PubkeyAuthentication=yes "root@${_HOSTNAME}" $@
    set -o pipefail
}

do_install_certificate()
{
    # Install SSL certificate
    ssh "root@${_HOSTNAME}" mkdir -p /etc/ssl/nginx/
    scp -r "${_SSL_CERTIFICATE_FILE}" "root@${_HOSTNAME}:/etc/ssl/nginx/${_HOSTNAME}.crt"
    scp -r "${_SSL_CERTIFICATE_KEY}" "root@${_HOSTNAME}:/etc/ssl/nginx/${_HOSTNAME}.key"
    # time openssl dhparam -out /etc/ssl/nginx/dhparam.pem 4096
    scp -r "${_DHPARAM_FILE}" "root@${_HOSTNAME}:/etc/ssl/nginx/dhparam.pem"
}

do_upload_files()
{
    # Upload some files
    ssh "root@${_HOSTNAME}" mkdir -p "/etc/nginx/conf.d"
    scp -r "bucket_size.conf" "root@${_HOSTNAME}:/etc/nginx/conf.d/"
    scp -r "nextcloud.conf" "root@${_HOSTNAME}:/etc/nginx/conf.d/"
    ssh "root@${_HOSTNAME}" mkdir -p "/usr/local/bin"
    scp -r "nextcloud-set-permissions.sh" "root@${_HOSTNAME}:/usr/local/bin/"
    ssh "root@${_HOSTNAME}" mkdir -p "/etc/systemd/system/php-fpm.service.d"
    scp -r "override.conf" "root@${_HOSTNAME}:/etc/systemd/system/php-fpm.service.d/"
    ssh "root@${_HOSTNAME}" mkdir -p "/etc/php/conf.d"
    scp -r "nextcloud.ini" "root@${_HOSTNAME}:/etc/php/conf.d/"
    scp -r "nextcloud-cron.service" "root@${_HOSTNAME}:/etc/systemd/system/"
    scp -r "nextcloud-cron.timer" "root@${_HOSTNAME}:/etc/systemd/system/"
    scp -r "php-fpm-restart.service" "root@${_HOSTNAME}:/etc/systemd/system/"
    scp -r "php-fpm-restart.timer" "root@${_HOSTNAME}:/etc/systemd/system/"
    ssh "root@${_HOSTNAME}" mkdir -p "/etc/webapps/nextcloud/config"
    scp -r "config.php" "root@${_HOSTNAME}:/etc/webapps/nextcloud/config/"
}

do_install_mysql()
{
    # MariaDB installation
    pacman -Syu --noconfirm mariadb
    sed -i '/\[mysqld\]/a bind-address = 127.0.0.1' /etc/my.cnf.d/server.cnf
    mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
    systemctl enable --now mariadb
    cat << EOF | mysql -u root
        DELETE FROM mysql.global_priv WHERE User='';
        DELETE FROM mysql.global_priv WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
        DROP DATABASE IF EXISTS test;
        DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${_MYSQL_ROOT_PASSWORD}';
        CREATE DATABASE nextcloud DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
        CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY '${_MYSQL_NEXTCLOUD_PASSWORD}';
        GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'localhost';
        FLUSH PRIVILEGES;
EOF
    sed -i '/\[mysqld\]/a unix_socket = OFF' /etc/my.cnf.d/server.cnf
    systemctl restart mariadb
}

do_install_nginx()
{
    # Install NGINX
    pacman -Syu --noconfirm nginx
    sed -i '$ i \    include conf.d/*.conf;' /etc/nginx/nginx.conf
    sed -i "s#cloud.example.com#${HOSTNAME}#" "/etc/nginx/conf.d/nextcloud.conf"
    nginx -t
}

do_install_nextcloud()
{
    # Nextcloud installation
    pacman -Syu --noconfirm sudo php-fpm php-intl php-apcu php-imagick nextcloud # php-mcrypt
    sed -i "s#cloud.example.com#${HOSTNAME}#" "/etc/webapps/nextcloud/config/config.php"
    chown http "/etc/webapps/nextcloud/config/config.php"
    useradd --system --create-home nextcloud
    chgrp http "/home/nextcloud"
    chmod g=rwx "/home/nextcloud"
    ln -sf "/home/nextcloud/apps2/" "/usr/share/webapps/nextcloud/apps2"
    /usr/local/bin/nextcloud-set-permissions.sh
    # PHP configuration
    sed -i '/;env\[PATH\]/s/^\;//' "/etc/php/php-fpm.d/www.conf"
    sed -i '/pm.max_children/s/5$/10/' "/etc/php/php-fpm.d/www.conf"
    sed -i '/pm.start_servers/s/2$/8/' "/etc/php/php-fpm.d/www.conf"
    sed -i '/pm.min_spare_server/s/1$/8/' "/etc/php/php-fpm.d/www.conf"
    sed -i '/pm.max_spare_server/s/3$/10/' "/etc/php/php-fpm.d/www.conf"
    # Add occ alias
    echo "alias occ='sudo -u http /usr/share/webapps/nextcloud/occ'" > ~/.bash_aliases
    # Setup services and timers
    systemctl enable php-fpm-restart.timer
    systemctl enable nextcloud-cron.timer
    systemctl enable nginx
    systemctl enable php-fpm
}

#
# Program start
#
set -e
set -u
set -o pipefail

# Check arguments count
if [ $# -lt 7 ]
then
  # Show usage
  do_usage
fi

# Set step value with default value
_STEP="${_STEP:=0}"

case ${_STEP} in
  0)
    do_instructions
    ;;
  1)
    # Install SSL certificate
    do_install_certificate
    # Upload files
    do_upload_files
    # Upload a copy of this script
    scp "$0" "root@${_HOSTNAME}":/root
    # Execute the next step in the remote system
    do_remote_command "bash \"/root/$(basename "$0")\"
                            \"${_HOSTNAME}\"
                            \"${_MYSQL_ROOT_PASSWORD}\"
                            \"${_MYSQL_NEXTCLOUD_PASSWORD}\"
                            \"${_SSL_CERTIFICATE_FILE}\"
                            \"${_SSL_CERTIFICATE_KEY}\"
                            \"${_DHPARAM_FILE}\"
                            2"
    # Operation successfull
    echo "installation completed, please wait until the system reboots"
    sleep 5
    echo "press CTRL+C to stop the ping activity"
    ping "${_HOSTNAME}"
    ;;
  2)
    # Install MySQL
    do_install_mysql
    # Install nginx
    do_install_nginx
    # Install Nextcloud
    do_install_nextcloud
    # Save all data, reboot and disconnect from the remote site
    echo "saving all data and rebooting the system..."
    sync
    nohup reboot -f &> /dev/null < /dev/null &
    exit 0
    ;;
esac

exit 4
