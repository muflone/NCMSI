#!/bin/bash
app_path='/usr/share/webapps/nextcloud'
data_path='/home/nextcloud'
config_path='/etc/webapps/nextcloud'
app_user='nextcloud'
http_user='http'
http_group='http'
root_user='root'

printf "Creating possible missing Directories\n"
mkdir -p "${data_path}/data"
mkdir -p "${data_path}/apps2"
mkdir -p "${data_path}/themes"

printf "chmod Files and Directories\n"
find "${app_path}/" -type f -print0 | xargs -0 chmod 0640
find "${app_path}/" -type d -print0 | xargs -0 chmod 0750
find "${data_path}/" -type f -print0 | xargs -0 chmod 0660
find "${data_path}/" -type d -print0 | xargs -0 chmod 0770

printf "chown Directories\n"
chown -R ${root_user}:${http_group} "${app_path}"
chown -R ${app_user}:${http_group} "${data_path}/data"
chown -R ${http_user}:${http_group} "${data_path}/apps2"
chown -R ${app_user}:${http_group} "${data_path}/themes"
chown -R ${http_user}:${http_group} "${config_path}"

chmod +x ${app_path}/occ

printf "chmod/chown .htaccess\n"
if [ -f ${app_path}/.htaccess ]
 then
  chmod 0644 ${app_path}/.htaccess
  chown ${root_user}:${http_group} ${app_path}/.htaccess
fi
