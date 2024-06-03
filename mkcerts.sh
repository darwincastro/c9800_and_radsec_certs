#!/usr/bin/env bash

# Load environment variables
export "$(grep -v '^#' .env | xargs)"

# Define colors for output
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RESET="\033[0m"

# Check if openssl is installed
[ ! -x /usr/bin/openssl ] && echo -e "${RED}Openssl not found.${RESET}" && exit 1

# Generate CA key
echo -e "${CYAN}Generating CA key${RESET}"
openssl genrsa -out ca.key && echo -e "\n${YELLOW}Please add the ROOT-CA information${RESET}"
openssl req -x509 -sha256 -new -nodes -key ca.key -days 14610 -out ca.pem -config .ca.cnf

# Generate WLC key and certificate
echo -e "${CYAN}Generating WLC key${RESET}"
openssl genrsa -des3 -out wlc.key -passout pass:${PASS} 4096 && echo -e "\n${YELLOW}Please add the WLC information${RESET}"
openssl req -new -sha256 -key wlc.key -out wlc.csr -config .device.cnf -passin pass:${PASS}

echo -e "\n${YELLOW}Please copy the above WLC FQDN input${RESET}" && read -p 'paste here: ' wlc_fqdn
echo -e "\n${YELLOW}Please enter your WLC IP${RESET}" && read -p 'IP: ' wlc_ip

if [[ $wlc_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo $wlc_ip > /dev/null 2>&1
else
    echo -e "${RED}Wrong Input.${RESET}"
    exit 1
fi

wlc_output="subjectAltName=DNS:${wlc_fqdn},IP:${wlc_ip}"
echo "$wlc_output" > wlc_extfile.cnf

openssl x509 -req -sha256 -in wlc.csr -CA ca.pem -CAkey ca.key -CAcreateserial -days 365 -extfile wlc_extfile.cnf -out wlc.pem > /dev/null 2>&1

# Generate RADSEC Server key and certificate
echo -e "${CYAN}Generating RADSEC Server key${RESET}"
openssl genrsa -des3 -out radsec.key -passout pass:${PASS} 4096 && echo -e "\n${YELLOW}Please add the RADSEC Server information${RESET}"
openssl req -new -sha256 -key radsec.key -out radsec.csr -config .device.cnf -passin pass:${PASS}

echo -e "\n${YELLOW}Please copy the above RADSEC Server FQDN input${RESET}" && read -p 'paste here: ' radsec_fqdn
echo -e "\n${YELLOW}Please enter your RADSEC Server IP${RESET}" && read -p 'IP: ' radsec_ip

if [[ $radsec_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo $radsec_ip > /dev/null 2>&1
else
    echo -e "${RED}Wrong Input.${RESET}"
    exit 1
fi

radsec_output="subjectAltName=DNS:${radsec_fqdn},IP:${radsec_ip}"
echo "$radsec_output" > radsec_extfile.cnf

openssl x509 -req -sha256 -in radsec.csr -CA ca.pem -CAkey ca.key -CAcreateserial -days 365 -extfile radsec_extfile.cnf -out radsec.pem > /dev/null 2>&1

# Clean up intermediate files
rm wlc_extfile.cnf \
  wlc.csr \
  radsec_extfile.cnf \
  radsec.csr \
  ca.srl

# Output instructions for configuring the trustpoint
echo -e "\n${GREEN}Configure the trustpoint in your network WLC using the following:

crypto pki import <trustpoint name> pem terminal password cisco
 <paste contents of ca.pem>
 <paste contents of wlc.key>
 <paste contents of wlc.pem>${RESET}\n"

# Output instructions for configuring the RADSEC Server
echo -e "\n${GREEN}Configure the RADSEC certs within \"/etc/freeradius/3.0/certs\" using the following commands:

mv ca.pem /etc/freeradius/3.0/certs/ca.pem
mv radsec.pem /etc/freeradius/3.0/certs/radsec.pem
mv radsec.key /etc/freeradius/3.0/certs/radsec.key${RESET}\n"
