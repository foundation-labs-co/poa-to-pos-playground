rm -rf ./validator1/datadir/geth
rm -rf ./validator2/datadir/geth
rm -rf ./validator3/datadir/geth
rm -rf ./consensus/lighthouse-beacon
rm -rf ./consensus/validatordata-lighthouse
rm -rf ./consensus/beacondata
rm -f ./config/genesis.ssz
rm -f ./config/genesis.ssz.json

find ./config ! -name 'genesis.json' ! -name 'jwtsecret' -type f -exec rm -rf {} +
rm -rf ./config/tranches
