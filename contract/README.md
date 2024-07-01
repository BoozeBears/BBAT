# Booze Bears Allowance Token

## Who can Mint?

- Owner of a Booze Bear Token to own wallet
- RedirectionWallet when Owner of redirection is part of MerkleTree for the specific token

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/BoozeBearsAllowanceToken.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>

$ forge script --chain amoy script/BoozeBearsAllowanceToken.sol:NFTScript --rpc-url $AMOY_RPC_URL --broadcast -vvvv
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
