#!/bin/bash

set -e

#------------------------------------------------------------
# Variables
#------------------------------------------------------------

STARTMSG="[SQUID_ENTRYPOINT]"

SQUID_CONF="/etc/squid/squid.conf"
SQUID_PASS_FILE="/etc/squid/passwords"

echo "${STARTMSG} starting simplesquid entrypoint"

#------------------------------------------------------------
# Source network restrictions
#------------------------------------------------------------
[[ ! -z $ALLOWED_SRC_CIDRS ]] \
&& sed -i "s|# <ALLOWED_SRC_CIDRS>|acl allowed_src_cidrs src ${ALLOWED_SRC_CIDRS}|" "${SQUID_CONF}" \
&& sed -i "s|# <DENY_SRC_CIDRS>|http_access deny !allowed_src_cidrs|" "${SQUID_CONF}"

#------------------------------------------------------------
# Destination network restrictions
#------------------------------------------------------------
[[ ! -z $DENIED_DST_CIDRS ]] \
&& sed -i "s|# <DENIED_DST_CIDRS>|acl denied_dst_cidrs dst ${DENIED_DST_CIDRS}|" "${SQUID_CONF}" \
&& sed -i "s|# <DENY_DST_CIDRS>|http_access deny denied_dst_cidrs|" "${SQUID_CONF}"

#------------------------------------------------------------
# Destination domain restrictions
#------------------------------------------------------------
[[ ! -z $DENIED_DOMAINS ]] \
&& sed -i "s|# <DENIED_DOMAINS>|acl denied_domains ${DENIED_DOMAINS}|" "${SQUID_CONF}" \
&& sed -i "s|# <DENY_DOMAINS>|http_access deny denied_domains|" "${SQUID_CONF}"

# Setup authentication config
AUTH_CONFIG=<<EOFAUTH
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwords
auth_param basic realm proxy
acl authenticated proxy_auth REQUIRED
EOFAUTH

#------------------------------------------------------------
# Authentication
#------------------------------------------------------------
# If creds are NOT passed, this will allow all
# If creds are passed, then add them all to the passwords
# file and add the appropriate config
#
# Passwords should be in format: SQUID_CREDS="user1 pass1|user2 pass2|usern passn"
# If no creds passed, allow all
if [[ -z $SQUID_CREDS ]]; then
  ALLOW_RULE="http_access allow all"
# If creds are passed, create passwords file and require authentication
else
  ALLOW_RULE="http_access allow authenticated"
  IFS='|' -r read CRED_ARRAY <<< "${SQUID_CREDS}"
  for cred in "${CRED_ARRAY[@]}"; do
    htpasswd -bn $cred >> "${SQUID_PASS_FILE}"
  done
  sed -i "s|# <AUTHENTICATION_SETUP>|${AUTH_CONFIG}|" "${SQUID_CONF}"
fi

sed -i "s|# <ALLOW_RULE>|${ALLOW_RULE}|" "${SQUID_CONF}"

echo "$STARTMSG starting squid proxy..."
$(which squid) -f /etc/squid/squid.conf -NYCd 1
echo "$STARTMSG squid proxy stopped..."
