#!/bin/bash

##################################  create dir and file for tls cert generation ############################
function printHelp {
    echo "Usage: "
    echo " ./tls.sh [opt] [value] "
    echo "    -N: namespace"
    echo "    -o: number of orderers, default=1"
    echo "    -O: number of orderer organization, default=1"
    echo "    -p: number of peers peer organization, default=1"
    echo "    -r: number of peer organizations, default=1"
    exit -1
}

function genCAKeys {
    ##################################  peer0 tls cert generation ############################
    key_dir=$1
    key_name=$2
    echo "Generate CA certs, key_dir: $key_dir, key_name: $key_name"
    openssl ecparam -out ${key_dir}/ca-key.pem -name prime256v1 -genkey >> $TLS_LOG 2>&1
    openssl req -new -x509 -subj "/C=CN/ST=BJ/L=BJ/O=IBM/OU=CSL/CN=${key_name}" -key ${key_dir}/ca-key.pem -out ${key_dir}/ca-cert.pem -days 365 -config openssl.cnf >> $TLS_LOG  2>&1
}

function genNodeKeys {
    ##################################  peer0 tls cert generation ############################
    key_dir=$1
    key_name=$2
    namespace=$3
    echo "Generate Node keys, key_dir: $key_dir, key_name: $key_name, namespace: $namespace"
    openssl ecparam -out ${key_dir}/key.pem -name prime256v1 -genkey >> $TLS_LOG  2>&1
    openssl req -new  -subj "/C=CN/ST=BJ/L=BJ/O=IBM/OU=CSL/CN=${key_name}.${namespace}" -key ${key_dir}/key.pem -out nodecert.csr >> $TLS_LOG  2>&1
    openssl ca -in nodecert.csr -out ${key_dir}/cert.pem -cert ${key_dir}/ca-cert.pem -keyfile ${key_dir}/ca-key.pem -batch -extensions v3_req -config openssl.cnf >> $TLS_LOG  2>&1
}

namespace="mySpace"
nOrderer=1
nOrdererOrg=1
nPeersPerOrg=1
nPeerOrg=1
TLS_LOG=/var/tmp/tls.log
>$TLS_LOG

while getopts "N:o:O:p:r:" opt; do
  case $opt in
    # peer environment options
    N)
      namespace=$OPTARG
      echo "namespace: $namespace"
      ;;
    o)
      nOrderer=$OPTARG
      echo "number of orderers: $nOrderer"
      ;;

    O)
      nOrdererOrg=$OPTARG
      echo "number of orderer organizations: $nOrdererOrg"
      ;;

    p)
      nPeersPerOrg=$OPTARG
      echo "number of peers: $nPeersPerOrg"
      ;;

    r)
      nPeerOrg=$OPTARG
      echo "number of peer organizations: $nPeerOrg"
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


mkdir -p certs crl newcerts private
echo "01" > serial
cp /dev/null index.txt 

rm -rf tls

# orderer tls cert generation
for ((i=0; i<$nOrdererOrg; i++)); do
    orderer_org_idx=$((i+1))
    for ((j=0; j<$nOrderer; j++)); do
        orderer_idx=$((i*nOrdererOrg+j+1))
        mkdir -p tls/orderers/ordererOrg${orderer_org_idx}/orderer${orderer_idx}
        if [[ $j == 0 ]]; then
            genCAKeys tls/orderers/ordererOrg${orderer_org_idx}/orderer${orderer_idx} ordererOrg${orderer_org_idx}
        else
            # cp ca cert from first orderer in this org
            cp tls/orderers/ordererOrg${orderer_org_idx}/orderer$((i*nOrdererOrg+1))/ca-* tls/orderers/ordererOrg${orderer_org_idx}/orderer${orderer_idx}
        fi
        
        genNodeKeys tls/orderers/ordererOrg${orderer_org_idx}/orderer${orderer_idx} orderer${orderer_idx} $namespace
        cp tls/orderers/ordererOrg${orderer_org_idx}/orderer${orderer_idx}/ca-cert.pem $GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen/crypto-config/ordererOrganizations/ordererOrg${orderer_org_idx}/msp/cacerts/ordererOrg$((orderer_idx-1)).pem
    done
done

for ((i=0; i<$nPeerOrg; i++)); do
    peer_org_idx=$((i+1))
    for ((j=0; j<$nPeersPerOrg; j++)); do
        peer_idx=$((i*nPeerOrg+j+1))
        mkdir -p tls/peers/peerOrg${peer_org_idx}/peer${peer_idx}
        if [[ $j = 0 ]]; then
            genCAKeys tls/peers/peerOrg${peer_org_idx}/peer${peer_idx} peerOrg${peer_org_idx}
        else
            # cp ca cert from first peer in this org
            cp tls/peers/peerOrg${peer_org_idx}/peer$((i*nPeerOrg+1))/ca-* tls/peers/peerOrg${peer_org_idx}/peer${peer_idx}
        fi
        genNodeKeys tls/peers/peerOrg${peer_org_idx}/peer${peer_idx} peer${peer_idx} $namespace
        
        cp tls/peers/peerOrg${peer_org_idx}/peer$((i*nPeerOrg+1))/ca-cert.pem \
            $GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen/crypto-config/ordererOrganizations/ordererOrg1/msp/cacerts/peerOrg$((peer_idx-1)).pem

        cp tls/peers/peerOrg${peer_org_idx}/peer$((i*nPeerOrg+1))/ca-cert.pem \
            $GOPATH/src/github.com/hyperledger/fabric/common/tools/cryptogen/crypto-config/peerOrganizations/peerOrg${peer_org_idx}/msp/cacerts/peerOrg$((peer_idx-1)).pem
    done
done
