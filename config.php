<?php
$CONFIG = array (
  'instanceid' => '000000000000',
  'passwordsalt' => 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
  'secret' => 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB',
  'datadirectory' => '/home/nextcloud/data',
  'overwrite.cli.url' => 'https://cloud.example.com',
  'version' => '20.0.1.1',
  'installed' => true,
  'maintenance' => false,
  'trusted_domains' => 
  array (
    0 => 'owncloud.muflone.com',
    1 => 'nextcloud.muflone.com',
    2 => 'cloud.example.com',
  ),
  'apps_paths' => 
  array (
    0 => 
    array (
      'path' => '/usr/share/webapps/nextcloud/apps',
      'url' => '/apps',
      'writable' => false,
    ),
    1 => 
    array (
      'path' => '/usr/share/webapps/nextcloud/apps2',
      'url' => '/apps2',
      'writable' => true,
    ),
  ),
  'dbtype' => 'mysql',
  'dbname' => 'nextcloud',
  'dbhost' => 'localhost',
  'dbuser' => 'nextcloud',
  'dbpassword' => 'MYSQL_NEXTCLOUD_PASSWORD',
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'memcache.locking' => '\\OC\\Memcache\\APCu',
  'filelocking.enabled' => true,
  'integrity.check.disabled' => true,
  'mail_from_address' => 'owncloud',
  'loglevel' => 0,
  'theme' => '',
  'mysql.utf8mb4' => true,
  'encryption.legacy_format_support' => true,
  'encryption.key_storage_migrated' => false,
);
