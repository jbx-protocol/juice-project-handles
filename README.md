# Juicebox Project Handles

The JBProjectHandles contract manages reverse records that point from JB project IDs to ENS nodes. If the reverse record of a project ID is pointed to an ENS node with a TXT record matching the ID of that project, then the ENS node will be considered the "handle" for that project.

# Install Foundry

To get set up:

1. Install [Foundry](https://github.com/gakonst/foundry).

```bash
curl -L https://foundry.paradigm.xyz | sh
```

2. Install external lib(s)

```bash
git submodule update --init && yarn install
```

then run

```bash
forge update
```

3. Run tests:

```bash
forge test
```

4. Update Foundry periodically:

```bash
foundryup
```

# Deploy & verify

Using the solidity script and a private key, --sender needs to be the address controlled by this key.
To use a seed phrase, use --mnemonic-path and --mnemonic-index
To simulate the deployment, remove the --broadcast (same if verification fails and you want to give a second try without redeploying)

See the [Foundry Book for available options](https://book.getfoundry.sh/reference/forge/forge-create.html)

## Rinkeby

forge script DeployRinkeby --rpc-url $RINKEBY_RPC_PROVIDER_URL --broadcast --interactives 1 --sender $SENDER_ADDRESS --verify --etherscan-api-key $ETHERSCAN_API_KEY

## Mainnet

forge script DeployMainnet --rpc-url $RINKEBY_RPC_PROVIDER_URL --broadcast --interactives 1 --sender $SENDER_ADDRESS --verify --etherscan-api-key $ETHERSCAN_API_KEY

The deployments are stored in ./broadcast
