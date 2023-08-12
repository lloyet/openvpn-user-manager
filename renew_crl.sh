#!/bin/bash
set -oe pipefail

readonly SERVICE_NAME="openvpn-server@server"
readonly OPENVPN_DIR="/etc/openvpn"
readonly EASYRSA_DIR="${OPENVPN_DIR}/easy-rsa"
readonly SERVER_DIR="${OPENVPN_DIR}/server"
readonly PKI_DIR="${EASYRSA_DIR}/pki"

${EASYRSA_DIR}/easyrsa gen-crl

cp ${PKI_DIR}/crl.pem ${SERVER_DIR}/crl.pem

systemctl restart ${SERVICE_NAME}
