#!/bin/bash

if [ -z "$2" ]; then
	echo "usage: $0 jmeno.prijmeni ca_name"
	exit 1
fi

TARGET="$1"
SOURCE="jmeno.prijmeni"
CA_NAME="$2"
OPENVPN_DIR="/etc/openvpn/ca/${CA_NAME}/easy-rsa"
KEYS_DIR="${OPENVPN_DIR}/keys"
CONFIG_FILENAME="openvpn-${CA_NAME}.conf.ovpn"

cd "${OPENVPN_DIR}" || exit 1

# natahne si potrebné promnenne
. vars

# vytvori certifikát a klice do ./keys
./pkitool "${TARGET}@${CA_NAME}"

# remove previous configuration
rm -r "${KEYS_DIR}/${TARGET}-${CA_NAME}/"

# prepare new directories
mkdir -p "${KEYS_DIR}/${TARGET}-${CA_NAME}/keys/"

# copy config
cp "${KEYS_DIR}/example/${CONFIG_FILENAME}" "${KEYS_DIR}/${TARGET}-${CA_NAME}/"

# copy newly created keys
cp "${KEYS_DIR}/${TARGET}@${CA_NAME}.crt" "${KEYS_DIR}/${TARGET}-${CA_NAME}/keys/"
cp "${KEYS_DIR}/${TARGET}@${CA_NAME}.csr" "${KEYS_DIR}/${TARGET}-${CA_NAME}/keys/"
cp "${KEYS_DIR}/${TARGET}@${CA_NAME}.key" "${KEYS_DIR}/${TARGET}-${CA_NAME}/keys/"

# ca is still the same
cp "${KEYS_DIR}/ca.crt" "${KEYS_DIR}/${TARGET}-${CA_NAME}/keys/"

sed -i "s/${SOURCE}/${TARGET}/g" "${KEYS_DIR}/${TARGET}-${CA_NAME}/${CONFIG_FILENAME}"

cd "${KEYS_DIR}" || exit 1
rar a -r "${KEYS_DIR}/rars/${TARGET}-${CA_NAME}.rar" "${TARGET}-${CA_NAME}"
