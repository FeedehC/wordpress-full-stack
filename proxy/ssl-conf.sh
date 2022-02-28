#!/bin/sh
set -e

DOMAINS=DOMAIN_NAME_VALUE

if [ -z $DOMAINS ]; then
	echo "DOMAIN[S] environment variable is not set"
	exit 1;
fi

if [ ! -f ../certbot/ssl-dhparam.pem ]; then
	openssl dhparam -out ../certbot/ssl-dhparam.pem 2048
fi

use_lets_encrypt_certificates() {
	echo "Switching Nginx to use Let's Encrypt certificate for $1"	
	sed -i '/location.*acme-challenge/,/}/ s/^[^#]/#/; /#location.\/./,/#}/ s/#//; s/#listen/listen/g; s/#ssl_/ssl_/g' ./conf.d/default.conf
	#sed -i '/#location.\/./,/#}/ s/#//' $PROXY_PREFIX/conf.d/default.conf
	#sed -i 's/#listen/listen/g' $PROXY_PREFIX/conf.d/default.conf
	#sed -i 's/#ssl_/ssl_/g' $PROXY_PREFIX/conf.d/default.conf	
}

reload_nginx() {
	echo "Reloading Nginx configuration"
	docker-compose stop proxy
	docker-compose start proxy
}

wait_for_lets_encrypt() {
	until [ -d "../certbot/live/$1" ]; do
		echo "Waiting for Let's Encrypt certificates for $1"
		sleep 5s & wait ${!}
	done
	use_lets_encrypt_certificates "$1"
	reload_nginx
}

for domain in $DOMAINS; do
	if [ ! -d "../certbot/live/$1" ]; then
		wait_for_lets_encrypt "$domain" &
	else
		use_lets_encrypt_certificates "$domain"
	fi
done

#docker-compose stop proxy
#docker-compose start proxy
