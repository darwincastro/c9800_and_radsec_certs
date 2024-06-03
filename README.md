# Certificates Generation Script

This script generates a Certificate Authority (CA) and two device certificates (WLC and RADSEC Server certificate) signed by the CA. The certificates are used for securing communication between network devices and FreeRADIUS server.

## Prerequisites

OpenSSL v1.1.1f or LibreSSL 3.3.6

## Steps to generate the certificate bundle:

1. Clone the repository, and go to the directory.

```sh
git clone https://github.com/darwincastro/c9800_and_radsec_certs.git
```

```sh
cd c9800_and_radsec_certs
```
2. Run the script:

```sh
./mkcerts.sh
```

The output should look like the following:

