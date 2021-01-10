#!/usr/bin/env bash

#
# dns-01 challenge for DuckDNS
# https://www.duckdns.org/spec.jsp

set -e
set -u
set -o pipefail

printf '\### token is: "%s\n' "$(cat "${DUCKDNS_TOKEN_FILE}")"
if [[ -z "${DUCKDNS_TOKEN_FILE}" ]] || [[ ! -r "${DUCKDNS_TOKEN_FILE}" ]]; then
  echo " - Unable to locate DuckDNS Token file in the environment! Make sure DUCKDNS_TOKEN_FILE environment variable is set and file is readable"
  exit 1
elif [[ -z "$(cat "${DUCKDNS_TOKEN_FILE}")" ]]; then
  echo "Unable to read DuckDNS Token from file at ${DUCKDNS_TOKEN_FILE}."
  exit 1
fi

deploy_challenge() {
  local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"
  echo -n " - Setting TXT record with DuckDNS ${TOKEN_VALUE}"
  curl "https://www.duckdns.org/update?domains=${DOMAIN}&token=$(cat "${DUCKDNS_TOKEN_FILE}")&txt=${TOKEN_VALUE}"
  echo
  echo " - Waiting 30 seconds for DNS to propagate."
  sleep 30
}

clean_challenge() {
  local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"
  echo -n " - Removing TXT record from DuckDNS ${DOMAIN}"
  curl "https://www.duckdns.org/update?domains=${DOMAIN}&token=$(cat "${DUCKDNS_TOKEN_FILE}")&txt=removed&clear=true"
  echo
}

deploy_cert() {
  local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}"
  if [[ -d /etc/nginx/ssl/ ]]; then
    cp "${KEYFILE}" "${FULLCHAINFILE}" /etc/nginx/ssl/; chown -R root: /etc/nginx/ssl
    systemctl reload nginx
  fi
}

unchanged_cert() {
  local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}"
  echo "The $DOMAIN certificate is still valid and therefore wasn't reissued."
}

HANDLER="$1"; shift
if [[ "${HANDLER}" =~ ^(deploy_challenge|clean_challenge|deploy_cert|unchanged_cert)$ ]]; then
  "$HANDLER" "$@"
fi
