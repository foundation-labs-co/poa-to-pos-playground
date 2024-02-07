INIT_SRC='--bootnodes ".*"'
INIT_DST="--bootnodes \"\""
sed -i -e "s|$INIT_SRC|$INIT_DST|g" docker-compose.yml

docker compose stop validator1 && docker compose stop validator2 && docker compose stop validator3

docker run --rm -it -v $PWD/validator1:/poa -v $PWD/genesis-merge.json:/config/genesis.json -w /poa ethereum/client-go:latest --datadir /poa/datadir init /config/genesis.json
docker run --rm -it -v $PWD/validator2:/poa -v $PWD/genesis-merge.json:/config/genesis.json -w /poa ethereum/client-go:latest --datadir /poa/datadir init /config/genesis.json
docker run --rm -it -v $PWD/validator3:/poa -v $PWD/genesis-merge.json:/config/genesis.json -w /poa ethereum/client-go:latest --datadir /poa/datadir init /config/genesis.json

docker compose up -d validator1

docker-compose exec -it validator1 geth --datadir datadir attach --exec 'admin.nodeInfo' 2>&1 | grep -o 'enode://.*@'

ENODE=$(docker-compose exec -it validator1 geth --datadir datadir attach --exec 'admin.nodeInfo' 2>&1 | grep -o 'enode://.*@')validator1:30456
# echo $ENODE
SRC='--bootnodes ".*"'
DST="--bootnodes \"$ENODE\""
sed -i -e "s|$SRC|$DST|g" docker-compose.yml

docker compose up -d
