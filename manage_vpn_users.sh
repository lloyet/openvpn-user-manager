#!/bin/bash
set -oe pipefail

readonly OPENVPN_DIR="/etc/openvpn"
readonly EASYRSA_DIR="${OPENVPN_DIR}/easy-rsa"
readonly CLIENT_DIR="${OPENVPN_DIR}/client"
readonly SERVER_DIR="${OPENVPN_DIR}/server"

readonly PKI_DIR="${EASYRSA_DIR}/pki"

readonly TEMPLATE="${CLIENT_DIR}/client-template.ovpn"
readonly OVPN_DIR="${CLIENT_DIR}/ovpn"

readonly CCD_DIR="${SERVER_DIR}/ccd"
readonly SERVERCONF="${SERVER_DIR}/server.conf"
readonly CRL="${SERVER_DIR}/crl.pem"

readonly SERVICE_NAME="openvpn-server@server"
readonly USER_LOGIN_REGEX="^[a-zA-Z_][0-9a-zA-Z_]*$"

log() {
	local message="$*"

	echo -e "$(date) ${message}"
}

error() {
	log $*
}

usage() {
	local message="$*"

	if [[ -n "${message}" ]]; then
		echo "${message}"
		echo
	fi

	echo "$0 <add|del|list|ovpn> <id>"
	echo
	echo "  * <add>:                        Add a new client"
	echo "  * <del>:                        Delete a client"
	echo "  * <list>:                       List all clients"
	echo "  * <ovpn>:                       Create or regenerate ${OVPN_DIR}/<clientname>.ovpn file"
	echo
	echo "  * <id>:                         A string respecting the regex '${USER_LOGIN_REGEX}'"
	exit 1
}

ovpn() {
	local clientname="$1"
	local ovpn="${OVPN_DIR}/${clientname}.ovpn"

	if ! grep -q "CN=${clientname}$" ${PKI_DIR}/index.txt; then
		log "Client ${clientname} not found"
		exit 1
	fi

	cat > ${ovpn} << EOF
$(cat ${TEMPLATE})
<ca>
$(cat ${PKI_DIR}/ca.crt)
</ca>
<cert>
$(awk '/BEGIN/,/END/' ${PKI_DIR}/issued/${clientname}.crt)
</cert>
<key>
$(cat ${PKI_DIR}/private/${clientname}.key)
</key>
<tls-crypt>
$(cat ${SERVER_DIR}/ta.key)
</tls-crypt>
EOF
	log "Client configuration file for user '${clientname}' can be found in ${ovpn}"
}

add() {
	local clientname="$1"
	local ovpn="${OVPN_DIR}/${clientname}.ovpn"
	local ccd="${CCD_DIR}/${clientname}"
	(cd ${EASYRSA_DIR} && ./easyrsa build-client-full "${clientname}" nopass)

	ovpn ${_type} ${clientname}

	log "New ${_type} client added with clientname '${clientname}'"
}

del() {
	local clientname="$1"
	local ovpn="${OVPN_DIR}/${clientname}.ovpn"
	local ccd="${CCD_DIR}/${clientname}"

	local serial=$(awk "/CN=${clientname}$/{print \$3}" ${PKI_DIR}/index.txt)
	if [[ -z "${serial}" ]]; then
		log "Unable to find client '${clientname}'"
		exit 1
	fi

	(cd ${EASYRSA_DIR} && ./easyrsa revoke ${clientname} && ./easyrsa gen-crl)
	
	cp -f ${PKI_DIR}/crl.pem ${SERVER_DIR}/crl.pem 

	rm -f ${PKI_DIR}/private/${clientname}.key
	rm -f ${PKI_DIR}/issued/${clientname}.crt
	rm -f ${PKI_DIR}/reqs/${clientname}.req
	rm -f ${PKI_DIR}/certs_by_serial/${serial}.pem
	sed -i "/CN=${clientname}$/d" ${PKI_DIR}/index.txt
	rm -f ${ovpn}

	systemctl restart ${SERVICE_NAME}

	log "${_type} client '${clientname}' has been removed"

}

list() {
	set -oe pipefail
	# skip the first line and print the clientname
	awk -F= 'NR>1{print $NF}' ${PKI_DIR}/index.txt
}

readonly ACTION="$1"
readonly ID="$2"

if [[ $# -ne 2 && $# -ne 3 && $# -ne 1 ]]; then
	 usage "Wrong number of arguments"
fi

if [[ ! "${ACTION}" =~ ^add|del|list|ovpn$ ]]; then
	usage "wrong action, must be 'list', 'add', 'del', 'ovpn'"
fi

CLIENTNAME="user_${ID}"

${ACTION} ${CLIENTNAME}
