VALIDATOR_VERSION=v1.10.26

INIT_SRC='--bootnodes ".*"'
INIT_DST="--bootnodes \"\""
sed -i -e "s|$INIT_SRC|$INIT_DST|g" docker-compose.yml


docker run --rm -it -v $PWD/validator1:/poa -v $PWD/genesis.json:/config/genesis.json -w /poa ethereum/client-go:$VALIDATOR_VERSION --datadir /poa/datadir init /config/genesis.json
# docker run --rm -it -v $PWD/validator2:/poa -v $PWD/genesis.json:/config/genesis.json -w /poa ethereum/client-go:$VALIDATOR_VERSION --datadir /poa/datadir init /config/genesis.json
# docker run --rm -it -v $PWD/validator3:/poa -v $PWD/genesis.json:/config/genesis.json -w /poa ethereum/client-go:$VALIDATOR_VERSION --datadir /poa/datadir init /config/genesis.json

VALIDATOR_DOCKER_TAG=$VALIDATOR_VERSION docker compose up -d validator1

# alternative call : curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":67}' http://0.0.0.0:8545/ 2>&1 | grep -o 'enode://.*@'
# ENODE1=$(docker-compose exec -it validator1 geth --datadir datadir attach --exec 'admin.nodeInfo' 2>&1 | grep -o 'enode://.*@')validator1:30456
# SRC='--bootnodes ".*"'
# DST="--bootnodes \"$ENODE1\""
# sed -i -e "s|$SRC|$DST|g" docker-compose.yml

# VALIDATOR_DOCKER_TAG=$VALIDATOR_VERSION docker compose up -d validator2 && VALIDATOR_DOCKER_TAG=$VALIDATOR_VERSION docker compose up -d validator3

# sleep 10

# VALIDATOR_DOCKER_TAG=$VALIDATOR_VERSION docker-compose exec -it validator1 geth --datadir datadir attach --exec 'clique.propose("0x2fe37d3Ded9F598EFb5Ea326fd8B49e47e2069b2", true)'

# sleep 10

# VALIDATOR_DOCKER_TAG=$VALIDATOR_VERSION docker-compose exec -it validator1 geth --datadir datadir attach --exec 'clique.propose("0x0896AA241bBf4e536b645cA722DA782a86Ce54a9", true)'
# VALIDATOR_DOCKER_TAG=$VALIDATOR_VERSION docker-compose exec -it validator2 geth --datadir datadir attach --exec 'clique.propose("0x0896AA241bBf4e536b645cA722DA782a86Ce54a9", true)'

# sleep 15

# ENODE2=$(docker-compose exec -it validator2 geth --datadir datadir attach --exec 'admin.nodeInfo' 2>&1 | grep -o 'enode://.*@')validator2:30456
# ENODE3=$(docker-compose exec -it validator3 geth --datadir datadir attach --exec 'admin.nodeInfo' 2>&1 | grep -o 'enode://.*@')validator3:30456
# SRC='--bootnodes ".*"'
# DST="--bootnodes \"$ENODE1,$ENODE2,$ENODE3\""
# sed -i -e "s|$SRC|$DST|g" docker-compose.yml

docker compose up -d validator1
# && docker compose up -d validator2 && docker compose up -d validator3
