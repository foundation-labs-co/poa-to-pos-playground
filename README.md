# Playground for Migrate POA to POS

## Usage
### Initial POA nodes
```
sh init-poa.sh # for starting 3 nodes of POA
```
### Migrate POA to POS by pre-configured
```
sh migrate-poa.sh # stop and init genesis-merge.json for the update
```
### Clean up *self destruction for any reason
```
sh clean.sh
```

## Key Configuration

- `genesis.json` default genesis for POA nodes before migrate
- `genesis-merge.json` updated genesis for migrate
- `config/` config for POS

## Reference Secret

```
Wallet: 

```