#!/bin/bash -e

# INIT_SRC='--bootnodes ".*"'
# INIT_DST="--bootnodes \"\""
# sed -i -e "s|$INIT_SRC|$INIT_DST|g" docker-compose.yml
if [ -s "config/deploy_block.txt" ]; then
    DEPOSIT_DEPLOY_BLOCK_NUMBER=$(cat config/deploy_block.txt)
    DEPOSIT_ADDRESS=$(cat config/deposit_contract.txt)
else
    DEPLOY_INFO=$(cd ./scripts && yarn deploy | grep -o 'deployed at: .*\|Contract deployed to address: .*')
    DEPOSIT_DEPLOY_BLOCK_NUMBER=$(echo $DEPLOY_INFO | cut -d ' ' -f 8)
    DEPOSIT_ADDRESS=$(echo $DEPLOY_INFO | cut -d ' ' -f 5)
    # sed -i -e "s|DEPOSIT_CONTRACT_ADDRESS=.*|DEPOSIT_CONTRACT_ADDRESS=$DEPOSIT_ADDRESS|g" ./config/config.yaml
    # cd ./scripts && yarn transfer && cd ..
    echo $DEPOSIT_DEPLOY_BLOCK_NUMBER >config/deploy_block.txt
    echo $DEPOSIT_DEPLOY_BLOCK_NUMBER >config/deposit_contract_block.txt
    echo $DEPOSIT_ADDRESS >config/deposit_contract.txt
fi

docker compose stop validator1
# && docker compose stop validator2 && docker compose stop validator3

EL_BLOCK_TIME=4 # clique block time
EL_TTD=50       # clique block target = TTD/2
EL_DELAY=60     # delay for startup CL

CL_SLOT_PER_EPOCH=32
CL_SLOT_TIME=4
CL_DENEB_FORK_EPOCH=2

GENESIS=$(date +%s)
TTD_TIME=$((($EL_TTD / 2) * $EL_BLOCK_TIME))
SHANGHAI_DELAY=$(($TTD_TIME + $EL_DELAY))
SHANGHAI=$(($GENESIS + $SHANGHAI_DELAY))

DENEB_FORK_SLOT=$(($CL_SLOT_PER_EPOCH * $CL_DENEB_FORK_EPOCH))
DENEB_FORK_EPOCH_TIME=$(($DENEB_FORK_SLOT * $CL_SLOT_TIME))
CANCUN_DELAY=$(($SHANGHAI_DELAY + $DENEB_FORK_EPOCH_TIME))
CANCUN=$(($GENESIS + $CANCUN_DELAY))

LONDON_BLOCK=10
sed -i -e "s|\"shanghaiTime\": .*,|\"shanghaiTime\": $SHANGHAI,|g" ./config/genesis.json
sed -i -e "s|\"cancunTime\": .*,|\"cancunTime\": $CANCUN,|g" ./config/genesis.json
sed -i -e "s|\"londonBlock\": .*,|\"londonBlock\": $LONDON_BLOCK,|g" ./config/genesis.json
sed -i -e "s|\"terminalTotalDifficulty\": .*,|\"terminalTotalDifficulty\": $EL_TTD,|g" ./config/genesis.json
echo "The merge will begin at $(date -j -v ${EL_DELAY}s)"

# GENESIS_HEX=$(cat genesis.json | grep -o '"timestamp": ".*"' | cut -d'"' -f 4)
# GENESIS=$((16${GENESIS_HEX/0x/#}))
# sed -i -e "s|MIN_GENESIS_TIME: .*|MIN_GENESIS_TIME: $MERGE_TIME|g" ./config/config.yaml
# sed -i -e "s|DEPOSIT_CONTRACT_ADDRESS: .*|DEPOSIT_CONTRACT_ADDRESS: $DEPOSIT_ADDRESS|g" ./config/config.yaml

# Write config genesis generetor
sed -i -e "s|GENESIS_TIMESTAMP=.*|GENESIS_TIMESTAMP=$MERGE_TIME|g" ./genesis-generator-config/values.env
sed -i -e "s|DEPOSIT_CONTRACT_ADDRESS=".*"|DEPOSIT_CONTRACT_ADDRESS="$DEPOSIT_ADDRESS"|g" ./genesis-generator-config/values.env
sed -i -e "s|CL_EXEC_BLOCK=".*"|CL_EXEC_BLOCK="$DEPOSIT_DEPLOY_BLOCK_NUMBER"|g" ./genesis-generator-config/values.env
sed -i -e "s/SLOTS_PER_EPOCH=\".*\"/SLOTS_PER_EPOCH=\"$CL_SLOT_PER_EPOCH\"/" ./genesis-generator-config/values.env
sed -i -e "s/SLOT_DURATION_IN_SECONDS=\".*\"/SLOT_DURATION_IN_SECONDS=\"$CL_SLOT_TIME\"/" ./genesis-generator-config/values.env
sed -i -e "s/DENEB_FORK_EPOCH=\".*\"/DENEB_FORK_EPOCH=\"$CL_DENEB_FORK_EPOCH\"/" ./genesis-generator-config/values.env
rm -rf genesis-generate-output && mkdir genesis-generate-output

docker run --rm -it -v $PWD/validator1:/poa -v $PWD/config/genesis.json:/config/genesis.json -w /poa ethereum/client-go:latest --datadir /poa/datadir init /config/genesis.json
# docker run --rm -it -v $PWD/validator2:/poa -v $PWD/genesis-merge.json:/config/genesis.json -w /poa ethereum/client-go:latest --datadir /poa/datadir init /config/genesis.json
# docker run --rm -it -v $PWD/validator3:/poa -v $PWD/genesis-merge.json:/config/genesis.json -w /poa ethereum/client-go:latest --datadir /poa/datadir init /config/genesis.json

docker compose up -d validator1

echo "wait for validator startup ..." && sleep 10

until [ "$(docker compose logs validator1 --tail=1 | grep -o 'number=[^ ]*' | cut -d '=' -f 2)" -ge $(($TTD / 2)) ]; do
    echo "Current block is $(docker compose logs validator1 --tail=1 | grep -o 'number=[^ ]*' | cut -d '=' -f 2) wait to $(($TTD / 2))..."
    sleep 3
done

echo "Current block Exceeded at $(($TTD / 2))" && sleep 10

curl -X POST -H "Content-Type: application/json" --data '{ "jsonrpc":"2.0","method":"eth_getBlockByNumber", "params":[ "latest", true ], "id":1 }' http://0.0.0.0:8545/ >genesis-generator-config/el/latest_block.json

docker run --rm -it -u $UID -v $PWD/genesis-generate-output:/data \
    -v $PWD/genesis-generator-config:/config \
    0xth0r/eth2-testnet-genesis:latest all

find ./genesis-generate-output/custom_config_data ! -name 'genesis.json' ! -name 'tranche_0000.txt' -type f -exec cp -fr {} ./config \; && \ 
cp -rf genesis-generate-output/custom_config_data/tranches config

docker run -it --rm \
    -v $PWD/consensus/validatordata-lighthouse:/root/lighthouse \
    -v $PWD/consensus/validatordata-lighthouse/custom/validators:/root/.lighthouse/custom/validators \
    -v $PWD/config:/config \
    -v ./validator_keys:/keys \
    sigp/lighthouse \
    lighthouse account validator import --directory=/keys --testnet-dir=/config --reuse-password

# sleep 5

# ENODE1=$(docker-compose exec -it validator1 geth --datadir datadir attach --exec 'admin.nodeInfo' 2>&1 | grep -o 'enode://.*@')validator1:30456
# SRC='--bootnodes ".*"'
# DST="--bootnodes \"$ENODE1\""
# sed -i -e "s|$SRC|$DST|g" docker-compose.yml

docker compose up -d
docker compose logs -f --tail 50

# ENODE2=$(docker-compose exec -it validator2 geth --datadir datadir attach --exec 'admin.nodeInfo' 2>&1 | grep -o 'enode://.*@')validator2:30456
# ENODE3=$(docker-compose exec -it validator3 geth --datadir datadir attach --exec 'admin.nodeInfo' 2>&1 | grep -o 'enode://.*@')validator3:30456
# SRC='--bootnodes ".*"'
# DST="--bootnodes \"$ENODE1,$ENODE2,$ENODE3\""
# sed -i -e "s|$SRC|$DST|g" docker-compose.yml

# docker compose up -d validator1 && docker compose up -d validator2 && docker compose up -d validator3
