#!/bin/bash

##################################  create dir and file for tls cert generation ############################
function printHelp {

   echo "Usage: "
   echo " ./tls.sh [opt] [value] "
   echo "    -N: namespace"
}

namespace="mySpace"
while getopts "N:" opt; do
  case $opt in
    # peer environment options
    N)
      namespace=$OPTARG
      echo "namespace: $namespace"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      printHelp
      ;;

    :)
      echo "Option -$OPTARG requires an argument." >&2
      printHelp
      ;;
  esac
done


mkdir certs crl newcerts private
echo "01" > serial
cp /dev/null index.txt 

rm -rf tls
mkdir tls tls/orderer tls/peers tls/peers/peer0 tls/peers/peer1 tls/peers/peer2 tls/peers/peer3


##################################  orderer tls cert generation ############################
openssl ecparam -out tls/orderer/ca-key.pem -name prime256v1 -genkey
openssl req -new -x509 -subj "/C=CN/ST=BJ/L=BJ/O=IBM/OU=CSL/CN=ordererOrg" -key tls/orderer/ca-key.pem -out tls/orderer/ca-cert.pem -days 365 -config openssl.cnf

openssl ecparam -out tls/orderer/key.pem -name prime256v1 -genkey
openssl req -new  -subj "/C=CN/ST=BJ/L=BJ/O=IBM/OU=CSL/CN=orderer0a" -key tls/orderer/key.pem -out nodecert.csr 
openssl ca -in nodecert.csr -out tls/orderer/cert.pem -cert tls/orderer/ca-cert.pem -keyfile tls/orderer/ca-key.pem -batch -extensions v3_req -config openssl.cnf


##################################  peer0 tls cert generation ############################
openssl ecparam -out tls/peers/peer0/ca-key.pem -name prime256v1 -genkey
openssl req -new -x509 -subj "/C=CN/ST=BJ/L=BJ/O=IBM/OU=CSL/CN=peerOrg1" -key tls/peers/peer0/ca-key.pem -out tls/peers/peer0/ca-cert.pem -days 365 -config openssl.cnf
openssl ecparam -out tls/peers/peer0/key.pem -name prime256v1 -genkey
openssl req -new  -subj "/C=CN/ST=BJ/L=BJ/O=IBM/OU=CSL/CN=peer0.${namespace}" -key tls/peers/peer0/key.pem -out nodecert.csr
openssl ca -in nodecert.csr -out tls/peers/peer0/cert.pem -cert tls/peers/peer0/ca-cert.pem -keyfile tls/peers/peer0/ca-key.pem -batch -extensions v3_req -config openssl.cnf

##################################  peer1 tls cert generation ############################
cp tls/peers/peer0/ca-* tls/peers/peer1/

openssl ecparam -out tls/peers/peer1/key.pem -name prime256v1 -genkey
openssl req -new  -subj "/C=CN/ST=BJ/L=BJ/O=IBM/OU=CSL/CN=peer1.${namespace}" -key tls/peers/peer1/key.pem -out nodecert.csr
openssl ca -in nodecert.csr -out tls/peers/peer1/cert.pem -cert tls/peers/peer1/ca-cert.pem -keyfile tls/peers/peer1/ca-key.pem -batch -extensions v3_req -config openssl.cnf


##################################  peer2 tls cert generation ############################
openssl ecparam -out tls/peers/peer2/ca-key.pem -name prime256v1 -genkey
openssl req -new -x509 -subj "/C=CN/ST=BJ/L=BJ/O=IBM/OU=CSL/CN=peerOrg2" -key tls/peers/peer2/ca-key.pem -out tls/peers/peer2/ca-cert.pem -days 365 -config openssl.cnf
openssl ecparam -out tls/peers/peer2/key.pem -name prime256v1 -genkey
openssl req -new  -subj "/C=CN/ST=BJ/L=BJ/O=IBM/OU=CSL/CN=peer2.${namespace}" -key tls/peers/peer2/key.pem -out nodecert.csr
openssl ca -in nodecert.csr -out tls/peers/peer2/cert.pem -cert tls/peers/peer2/ca-cert.pem -keyfile tls/peers/peer2/ca-key.pem -batch -extensions v3_req -config openssl.cnf

##################################  peer3 tls cert generation ############################
cp tls/peers/peer2/ca-* tls/peers/peer3/

openssl ecparam -out tls/peers/peer3/key.pem -name prime256v1 -genkey
openssl req -new  -subj "/C=CN/ST=BJ/L=BJ/O=IBM/OU=CSL/CN=peer3.${namespace}" -key tls/peers/peer3/key.pem -out nodecert.csr
openssl ca -in nodecert.csr -out tls/peers/peer3/cert.pem -cert tls/peers/peer3/ca-cert.pem -keyfile tls/peers/peer3/ca-key.pem -batch -extensions v3_req -config openssl.cnf


cp tls/peers/peer0/ca-cert.pem $GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen/crypto-config/ordererOrganizations/ordererOrg1/msp/cacerts/peerOrg0.pem
cp tls/peers/peer2/ca-cert.pem $GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen/crypto-config/ordererOrganizations/ordererOrg1/msp/cacerts/peerOrg1.pem
cp tls/orderer/ca-cert.pem     $GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen/crypto-config/ordererOrganizations/ordererOrg1/msp/cacerts/ordererOrg.pem
cp tls/peers/peer0/ca-cert.pem $GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen/crypto-config/peerOrganizations/peerOrg1/msp/cacerts/peerOrg0.pem
cp tls/peers/peer2/ca-cert.pem $GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen/crypto-config/peerOrganizations/peerOrg2/msp/cacerts/peerOrg1.pem

