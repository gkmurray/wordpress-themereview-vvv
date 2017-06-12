#!/usr/bin/env bash
# Provision WordPress Stable

# Make a database, if we don't already have one
echo -e "\nCreating database 'wordpress_themereview' (if it's not already there)"
mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS wordpress_themereview"
mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON wordpress_themereview.* TO wp@localhost IDENTIFIED BY 'wp';"
echo -e "\n DB operations done.\n\n"

# Nginx Logs
mkdir -p ${VVV_PATH_TO_SITE}/log
touch ${VVV_PATH_TO_SITE}/log/error.log
touch ${VVV_PATH_TO_SITE}/log/access.log

# Install and configure the latest stable version of WordPress
if [[ ! -d "${VVV_PATH_TO_SITE}/public_html" ]]; then

  echo "Downloading WordPress Stable, see http://wordpress.org/"
  cd ${VVV_PATH_TO_SITE}
  curl -L -O "https://wordpress.org/latest.tar.gz"
  noroot tar -xvf latest.tar.gz
  mv wordpress public_html
  rm latest.tar.gz
  cd ${VVV_PATH_TO_SITE}/public_html

  echo "Configuring WordPress Stable..."
  noroot wp core config --dbname=wordpress_themereview --dbuser=wp --dbpass=wp --quiet --extra-php <<PHP
// Match any requests made via xip.io.
if ( isset( \$_SERVER['HTTP_HOST'] ) && preg_match('/^(themereview.wordpress.)\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(.xip.io)\z/', \$_SERVER['HTTP_HOST'] ) ) {
    define( 'WP_HOME', 'http://' . \$_SERVER['HTTP_HOST'] );
    define( 'WP_SITEURL', 'http://' . \$_SERVER['HTTP_HOST'] );
}
define( 'WP_DEBUG', true );
PHP

  echo "Installing WordPress Stable..."
  noroot wp core install --url=themereview.wordpress.dev --quiet --title="themereview WordPress Dev" --admin_name=admin --admin_email="admin@change.me" --admin_password="password"


  # Install Sage
  noroot wp theme install 'https://github.com/gkmurray/sage/archive/develop.zip'

  # Install Plugins
  echo "Installing plugins..."
  noroot wp plugin install wordpress-importer --activate
  noroot wp plugin install developer --activate
  noroot wp plugin install theme-check --activate
  noroot wp plugin install theme-mentor --activate
  noroot wp plugin install what-the-file --activate
  noroot wp plugin install wordpress-database-reset --activate
  noroot wp plugin install rtl-tester
  noroot wp plugin install piglatin
  noroot wp plugin install debug-bar  --activate
  noroot wp plugin install debug-bar-console  --activate
  noroot wp plugin install debug-bar-cron  --activate
  noroot wp plugin install debug-bar-extender  --activate
  noroot wp plugin install rewrite-rules-inspector  --activate
  noroot wp plugin install log-deprecated-notices  --activate
  noroot wp plugin install log-deprecated-notices-extender  --activate
  noroot wp plugin install log-viewer  --activate
  noroot wp plugin install monster-widget  --activate
  noroot wp plugin install user-switching  --activate
  noroot wp plugin install regenerate-thumbnails  --activate
  noroot wp plugin install simply-show-ids  --activate
  noroot wp plugin install theme-test-drive  --activate
  noroot wp plugin install wordpress-beta-tester  --activate

  # Import the unit data.
  echo 'Installing unit test data...'
  curl -O https://wpcom-themes.svn.automattic.com/demo/theme-unit-test-data.xml
  noroot wp import theme-unit-test-data.xml --authors=create
  rm theme-unit-test-data.xml

  # Replace url from unit data
  echo 'Adjusting urls in database...'
  noroot wp search-replace 'wpthemetestdata.wordpress.com' 'themereview.wordpress.dev' --skip-columns=guid

else

  echo "Updating WordPress Stable..."
  cd ${VVV_PATH_TO_SITE}/public_html
  noroot wp core update

fi