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
echo "ALLOWED_SRC_CIDRS"
[[ ! -z $ALLOWED_SRC_CIDRS ]] \
&& sed -i 's|# <ALLOWED_SRC_CIDRS>|acl allowed_src_cidrs src '"${ALLOWED_SRC_CIDRS}"'|' "${SQUID_CONF}" \
&& sed -i 's|# <DENY_SRC_CIDRS>|http_access deny !allowed_src_cidrs|' "${SQUID_CONF}"

#------------------------------------------------------------
# Destination network restrictions
#------------------------------------------------------------
echo "DENIED_DST_CIDRS"
[[ ! -z $DENIED_DST_CIDRS ]] \
&& sed -i 's|# <DENIED_DST_CIDRS>|acl denied_dst_cidrs dst '"${DENIED_DST_CIDRS}"'|' "${SQUID_CONF}" \
&& sed -i 's|# <DENY_DST_CIDRS>|http_access deny denied_dst_cidrs|' "${SQUID_CONF}"

#------------------------------------------------------------
# Destination domain restrictions
#------------------------------------------------------------
echo "DENIED_DOMAINS"
[[ ! -z $DENIED_DOMAINS ]] \
&& sed -i 's|# <DENIED_DOMAINS>|acl denied_domains dstdomain '"${DENIED_DOMAINS}"'|' "${SQUID_CONF}" \
&& sed -i 's|# <DENY_DOMAINS>|http_access deny denied_domains|' "${SQUID_CONF}"

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
  IFS='|' read -ra CRED_ARRAY <<< "$SQUID_CREDS"
  for cred in "${CRED_ARRAY[@]}"; do
    htpasswd -bn $cred >> "${SQUID_PASS_FILE}"
  done
  echo "auth setup"
  sed -i 's|# <AUTH_LINE_1>|auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwords|' "${SQUID_CONF}"
  sed -i 's|# <AUTH_LINE_2>|auth_param basic realm proxy|' "${SQUID_CONF}"
  sed -i 's|# <AUTH_LINE_3>|acl authenticated proxy_auth REQUIRED|' "${SQUID_CONF}"
fi

echo "allow rule"
sed -i 's|# <ALLOW_RULE>|'"${ALLOW_RULE}"'|' "${SQUID_CONF}"

cat /etc/squid/squid.conf

#------------------------------------------------------------
# Start squid
#------------------------------------------------------------
echo "$STARTMSG starting squid proxy..."
$(which squid) -f /etc/squid/squid.conf -NYCd 1
echo "$STARTMSG squid proxy stopped..."
