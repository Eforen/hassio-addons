#!/usr/bin/env bashio

EMAIL=$(bashio::config 'email')
DOMAINS=$(bashio::config 'domains')
KEYFILE=$(bashio::config 'keyfile')
CERTFILE=$(bashio::config 'certfile')
CHALLENGE=$(bashio::config 'challenge')
DNS_PROVIDER=$(bashio::config 'dns.provider')

CERT_DIR=/data/letsencrypt
WORK_DIR=/data/workdir

mkdir -p "$WORK_DIR"
mkdir -p "$CERT_DIR"
mkdir -p "/ssl"
chmod +x /run.sh



# AWS Config
if [ $DNS_PROVIDER == "dns-route53" ]; then
    mkdir ~/.aws -p
    echo -e "[default]\n" \
        "aws_access_key_id = $(bashio::config 'dns.aws_access_key_id')\n" \
        "aws_secret_access_key = $(bashio::config 'dns.aws_secret_access_key')\n" > ~/.aws/config
    chmod 600 ~/.aws/config
else
    touch /data/dnsapikey
    echo -e "dns_cloudflare_email = $(bashio::config 'dns.cloudflare_email')\n" \
    "dns_cloudflare_api_key = $(bashio::config 'dns.cloudflare_api_key')\n" \
    "dns_cloudxns_api_key = $(bashio::config 'dns.cloudxns_api_key')\n" \
    "dns_cloudxns_secret_key = $(bashio::config 'dns.cloudxns_secret_key')\n" \
    "dns_digitalocean_token = $(bashio::config 'dns.digitalocean_token')\n" \
    "dns_dnsimple_token = $(bashio::config 'dns.dnsimple_token')\n" \
    "dns_dnsmadeeasy_api_key = $(bashio::config 'dns.dnsmadeeasy_api_key')\n" \
    "dns_dnsmadeeasy_secret_key = $(bashio::config 'dns.dnsmadeeasy_secret_key')\n" \
    "dns_gehirn_api_token = $(bashio::config 'dns.gehirn_api_token')\n" \
    "dns_gehirn_api_secret = $(bashio::config 'dns.gehirn_api_secret')\n" \
    "dns_linode_key = $(bashio::config 'dns.linode_key')\n" \
    "dns_linode_version = $(bashio::config 'dns.linode_version')\n" \
    "dns_luadns_email = $(bashio::config 'dns.luadns_email')\n" \
    "dns_luadns_token = $(bashio::config 'dns.luadns_token')\n" \
    "dns_nsone_api_key = $(bashio::config 'dns.nsone_api_key')\n" \
    "dns_ovh_endpoint = $(bashio::config 'dns.ovh_endpoint')\n" \
    "dns_ovh_application_key = $(bashio::config 'dns.ovh_application_key')\n" \
    "dns_ovh_application_secret = $(bashio::config 'dns.ovh_application_secret')\n" \
    "dns_ovh_consumer_key = $(bashio::config 'dns.ovh_consumer_key')\n" \
    "dns_rfc2136_server = $(bashio::config 'dns.rfc2136_server')\n" \
    "dns_rfc2136_port = $(bashio::config 'dns.rfc2136_port')\n" \
    "dns_rfc2136_name = $(bashio::config 'dns.rfc2136_name')\n" \
    "dns_rfc2136_secret = $(bashio::config 'dns.rfc2136_secret')\n" \
    "dns_rfc2136_algorithm = $(bashio::config 'dns.rfc2136_algorithm')\n" \
    "dns_sakuracloud_api_token = $(bashio::config 'dns.sakuracloud_api_token')\n" \
    "dns_sakuracloud_api_secret = $(bashio::config 'dns.sakuracloud_api_secret')" > /data/dnsapikey
    chmod 600 /data/dnsapikey
fi

# Print out plugins
#echo "-- Start Plugin List --" # for debugging
#echo "$(certbot plugins)" # for debugging
#echo "-- End Plugin List --" # for debugging


#echo "Sleeping before cirt" # for debugging
#sleep 600 # for debugging

# Generate new certs
if [ ! -d "$CERT_DIR/live" ]; then
    DOMAIN_ARR=()
    for line in $DOMAINS; do
        DOMAIN_ARR+=(-d "$line")
    done

    echo "$DOMAINS" > /data/domains.gen
    if [ "$CHALLENGE" == "dns" ]; then
        if [ $DNS_PROVIDER == "dns-route53" ]; then
            certbot certonly --non-interactive --config-dir "$CERT_DIR" --work-dir "$WORK_DIR" "--$DNS_PROVIDER" --email "$EMAIL" --agree-tos --config-dir "$CERT_DIR" --work-dir "$WORK_DIR" --preferred-challenges "$CHALLENGE" "${DOMAIN_ARR[@]}"
        else
            certbot certonly --non-interactive --config-dir "$CERT_DIR" --work-dir "$WORK_DIR" "--$DNS_PROVIDER" "--${DNS_PROVIDER}-credentials" "/data/dnsapikey" --email "$EMAIL" --agree-tos --config-dir "$CERT_DIR" --work-dir "$WORK_DIR" --preferred-challenges "$CHALLENGE" "${DOMAIN_ARR[@]}"
        fi
    else
        certbot certonly --non-interactive --standalone --email "$EMAIL" --agree-tos --config-dir "$CERT_DIR" --work-dir "$WORK_DIR" --preferred-challenges "$CHALLENGE" "${DOMAIN_ARR[@]}"
    fi
else
    certbot renew --non-interactive --config-dir "$CERT_DIR" --work-dir "$WORK_DIR" --preferred-challenges "$CHALLENGE"
fi

echo "Dumping Certs to Store"
# copy certs to store
mkdir /ssl/letsencrypt -p
#cp "$CERT_DIR"/* "/ssl/letsencrypt" -r # for debugging 
cp "$CERT_DIR"/live/*/privkey.pem "/ssl/$KEYFILE"
cp "$CERT_DIR"/live/*/fullchain.pem "/ssl/$CERTFILE"
# echo "Sleeping after copy" # for debugging 
# sleep 600 # for debugging 
# echo "Done sleeping" # for debugging 