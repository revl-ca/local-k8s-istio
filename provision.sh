#!/usr/bin/env bash

set -e

# TODO: Changing KEYCLOAK_REALM seems to break something

KEYCLOAK_HOST=${KEYCLOAK_HOST:="http://keycloak.keycloak.svc.cluster.local:8080"}
KEYCLOAK_REALM=${KEYCLOAK_REALM:="test-istio"}
KEYCLOAK_USERNAME=${KEYCLOAK_USERNAME:="admin"}
KEYCLOAK_PASSWORD=${KEYCLOAK_PASSWORD:="admin"}

parse_json_property() {
  local PROPERTY="$1"

  python -c "import json, sys; print json.load(sys.stdin)[sys.argv[1]];" "$PROPERTY"
}

realm_payload() {
  local REALM="$1"

  cat <<EOF
{
  "enabled": true,
  "id": "$REALM",
  "realm": "$REALM"
}
EOF
}

TOKEN=$(curl --silent -X POST $KEYCLOAK_HOST/auth/realms/master/protocol/openid-connect/token --data "grant_type=password&client_id=admin-cli&username=$KEYCLOAK_USERNAME&password=$KEYCLOAK_PASSWORD" | parse_json_property "access_token")

curl -X POST \
    --header "Authorization: Bearer $TOKEN" \
    --header "Content-Type: application/json;charset=UTF-8" \
    --header "Accept: application/json, text/plain, */*" \
    --data-binary "$(realm_payload "$KEYCLOAK_REALM")" \
    $KEYCLOAK_HOST/auth/admin/realms

envsubst '${KEYCLOAK_REALM}' < payload-import.json | curl -X POST \
    --header "Authorization: Bearer $TOKEN" \
    --header "Content-Type: application/json;charset=UTF-8" \
    --header "Accept: application/json, text/plain, */*" \
    --data-binary @- \
    $KEYCLOAK_HOST/auth/admin/realms/test-istio/partialImport

