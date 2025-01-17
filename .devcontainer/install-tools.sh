#! /bin/bash

# Refreshing source and paths
source ~/.bashrc
SETUP_PATH="$( dirname -- "$( readlink -f -- "$0"; )"; )"

# Catching every output signal to a logfile.
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>"$SETUP_PATH"/logs/setup.log 2>&1

# Visual Studio Code - Readjust launch.json based on .env property
sed -i 's|__WORDPRESS_DEV_ITEM_PATH__|'"$WORDPRESS_DEV_ITEM_PATH"'|' "$SETUP_PATH"/../.vscode/launch.json

# PHP Tooling - WordPress Coding Standards
echo "Installing WordPress Coding Standards..."
git clone -b master https://github.com/WordPress/WordPress-Coding-Standards.git /var/www/.wpcs
sudo phpcs --config-set installed_paths /var/www/.wpcs/
sudo phpcs --config-set default_standard WordPress

# PHP Tooling - Compatibility Paragonie
echo "Installing Compatibility Paragonie..."
git clone -b master https://github.com/PHPCompatibility/PHPCompatibilityParagonie.git /var/www/.phpcp
sudo phpcs --config-set installed_paths /var/www/.wpcs/,/var/www/.phpcp/

# PHP Tooling - PHPCompatibility
echo "Installing PHP Compatibility..."
git clone -b master https://github.com/PHPCompatibility/PHPCompatibility.git /var/www/.phpc
sudo phpcs --config-set installed_paths /var/www/.wpcs/,/var/www/.phpcp/,/var/www/.wpc/

# PHP Tooling - PHPCompatibilityWP
echo "Installing PHP Compatibility WP..."
git clone -b master https://github.com/PHPCompatibility/PHPCompatibilityWP.git /var/www/.phpcwp
sudo phpcs --config-set installed_paths /var/www/.wpcs/,/var/www/.phpcp/,/var/www/.phpc/,/var/www/.phpcwp/

# PHP Tooling - WooCommerce Sniffs
echo "Installing WooCommerce Sniffs..."
git clone -b trunk https://github.com/woocommerce/woocommerce-sniffs/ /var/www/.woocs
sudo phpcs --config-set installed_paths /var/www/.wpcs/,/var/www/.phpcp/,/var/www/.phpc/,/var/www/.phpcwp/,/var/www/.woocs/src/

# NodeJS Tooling - Install dependencies and other stuff for blocks if using wp-scripts
# echo "Installing NodeJS dependencies.."
# Ref: https://developer.wordpress.org/block-editor/reference-guides/packages/packages-scripts/
# cd /var/www/html${WORDPRESS_DEV_ITEM_PATH}
# npm i && npm run build

# Wait to DB to be ready (maybe it's not needed but just to be sure).
echo "Waiting for DB image to be ready..."
sleep 5s

# WordPress - Determine environment (local/codespace)
if [[ "$CODESPACES" ]]
then
	WORDPRESS_SITE_HOST="https://${CODESPACE_NAME}-${WORDPRESS_WWW_PORT}.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
else
	WORDPRESS_SITE_HOST="http://localhost:${WORDPRESS_WWW_PORT}"
fi

# WordPress - Setting title
if [[ -z "$WORDPRESS_WWW_TITLE" ]]
then
    WORDPRESS_WWW_TITLE="WordPress Development"
fi

# WordPress - Install WordPress.
echo "Starting WordPress project '$WORDPRESS_WWW_TITLE' in '/var/www/html'..."
cd /var/www/html/

# Install NPM utils
npm install -g n
sudo /var/www/.nvm/versions/node/v18.16.1/bin/n lts
sudo /var/www/.nvm/versions/node/v18.16.1/bin/n latest
sudo /var/www/.nvm/versions/node/v18.16.1/bin/n prune

echo "Setting up WordPress at $WORDPRESS_SITE_HOST"
wp core install \
    --url="$WORDPRESS_SITE_HOST" \
    --title="$WORDPRESS_WWW_TITLE" \
    --locale="$WORDPRESS_LOCALE" \
    --admin_user="$WORDPRESS_WWW_ROOT_USER" \
    --admin_password="$WORDPRESS_WWW_ROOT_PASSWORD" \
    --admin_email="$WORDPRESS_WWW_ROOT_EMAIL" \
    --skip-email

# Configure language
wp language core install "$WORDPRESS_LOCALE"

# WordPress - Install WordPress and activate plugins/themes.
wp plugin activate cl-this-plugin # Activate this development plugin
# wp plugin install woocommerce --activate # To install and activate plugin repository
wp plugin install generateblocks --activate # To install and activate plugin repository
wp plugin install query-monitor --activate # To install and activate plugin repository
wp plugin install wp-crontrol --activate # To install and activate plugin repository
wp theme install generatepress --activate # To install and activate plugin repository
wp plugin delete hello
wp plugin delete akismet
wp theme delete twentytwentytwo
wp theme delete twentytwentyone

# Change to WordPress installation root.
cd /var/www/html