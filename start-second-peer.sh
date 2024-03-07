ENODE1=$(docker-compose exec -it validator1 geth --datadir datadir attach --exec 'admin.nodeInfo' 2>&1 | grep -o 'enode://.*@')validator1:30456
SRC='--bootnodes ".*"'
DST="--bootnodes \"$ENODE1\""
sed -i -e "s|$SRC|$DST|g" second-peer.yml

docker run --rm -it -v $PWD/geth-second:/poa -v $PWD/config/genesis.json:/config/genesis.json -w /poa ethereum/client-go:latest --datadir /poa/datadir init /config/genesis.json

docker compose -f second-peer.yml up -d geth-second

docker run -it --rm \
    -v $PWD/consensus/validatordata-lighthouse-second:/root/lighthouse \
    -v $PWD/consensus/validatordata-lighthouse-second/custom/validators:/root/.lighthouse/custom/validators \
    -v $PWD/config:/config \
    -v ./validator_keys_second:/keys \
    sigp/lighthouse \
    lighthouse account validator import --directory=/keys --testnet-dir=/config --reuse-password
