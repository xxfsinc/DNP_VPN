#!/bin/bash

# Initialize APP
echo "Initializing App..."


[ -z "$_DAPPNODE_GLOBAL_HOSTNAME" ] || echo -n "Global variables not loaded yet. Waiting"
while [ -z "$_DAPPNODE_GLOBAL_HOSTNAME" ]; do
    echo -n "."
    sleep 2
done
[ -n "$_DAPPNODE_GLOBAL_HOSTNAME" ] || echo "Public hostname loaded: ${_DAPPNODE_GLOBAL_HOSTNAME}"
VPNHOSTNAME=${_DAPPNODE_GLOBAL_HOSTNAME}

# check and generate random seed
if [ ! -f "${OPENVPN}/salt" ]; then
  head /dev/urandom | tr -dc a-f0-9 | head -c 16 > "${OPENVPN}/salt"
fi
OVPN_CN="$(cat ${OPENVPN}/salt)"

node src/initializeApp.js
echo "Initialized App"

# Initialize config and PKI
# -c: Client to Client
# -d: disable default route (disables NAT without '-N')
# -p "route 172.33.0.0 255.255.0.0": Route to push to the client
# -n "172.33.1.2": DNS server (BIND)
ovpn_genconfig -c -d -u udp://"${VPNHOSTNAME}" -s 172.33.8.0/22 \
    -p "route 172.33.0.0 255.255.0.0" -n "172.33.1.2"

# check if PKI is initalized already, if not use hostname as CN
OVPN_CN=$(cat "${SERVER_NAME_PATH}")
export OVPN_CN
if [ ! -d "${OPENVPN}/pki/reqs" ] || [ ! "$(ls -A ${OPENVPN}/pki/reqs)" ]; then
    echo "Initializing PKI"
    EASYRSA_REQ_CN=${OVPN_CN} ovpn_initpki nopass
fi

# Create admin user
if [ ! -e "${OPENVPN_ADMIN_PROFILE}" ]; then
    vpncli add "${DEFAULT_ADMIN_USER}"
    vpncli get "${DEFAULT_ADMIN_USER}"
    echo "ifconfig-push 172.33.10.1 255.255.252.0" > "${OPENVPN_CCD_DIR}/${DEFAULT_ADMIN_USER}"
fi

# Enable Proxy ARP (needs privileges)
echo 1 > /proc/sys/net/ipv4/conf/eth0/proxy_arp

# Save environment
env | sed '/affinity/d' > /etc/env.sh

# Supervisord processes:
supervisord -c supervisord.conf
