# OPENVPN Startup script

> A simplify script to manage USER certificates.

## Features

- Create **_USER_** certificates with `manage_vpn_users add USER_NAME`
- Delete **_USER_** certificates with `manage_vpn_users del USER_NAME`
- Generate **_USER_** ovpn certificates with `manage_vpn_users ovpn USER_NAME`
- Display all vpn certificates with `manage_vpn_users list`

## Generate certificates

> To add **_ETIC_** certificates, run sh `manage_vpn_users add etic NUMBER` script

```sh
# Add new certification with id=etic0 and password automatically generated
./manage_vpn_users add etic 0
```

> To del **_USER_** certificates, simply run sh `manage_vpn_users del USER_NAME` script

```sh
# Delete certification with user=USER_NAME and password automatically generated
./manage_vpn_users del foo
```

## Troubleshooting

### Renew expired CRL certificates

Every 6 months (180 days) Certificate Revocation List needs to be updated. After that you need to replace openvpn `crl.pem` and restart daemon.

```sh
# To show current CRL informations
openssl crl -in pki/crl.pem --text

# To regenerate CRL
./easyrsa gen-crl

# Or with openssl
./vars && openssl ca -gencrl -keyfile ca.key -cert ca.crt -out crl.pem -config openssl.cnf
```

By default `easy-rsa` revocate CRL every 180 days, but you can change it from configuration `vars` file.

```sh
# Example of ./vars easy-rsa config file
set_var EASYRSA_REQ_COUNTRY		"YOUR_COUNTRY"
set_var EASYRSA_REQ_PROVINCE	"YOUR_PROVINCE"
set_var EASYRSA_REQ_CITY		"YOUR_CITY"
set_var EASYRSA_REQ_ORG			"YOUR_ORG"
set_var EASYRSA_REQ_OU			"YOUR_NAME"

...

set_var EASYRSA_CRL_DAYS		365
```

## Documentation

- Tutorial openVPN [Openvpn Setup Digital ocean](https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-an-openvpn-server-on-ubuntu-20-04-fr)
- Tutorial AC [AC Setup Digital ocean](https://www.digitalocean.com/community/tutorials/how-to-set-up-and-configure-a-certificate-authority-ca-on-ubuntu-20-04)
