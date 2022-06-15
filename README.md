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

Using the solidity script after configuring the .env accordingly (the sender address must be corresponding to the private key)

See the [Foundry Book for available options](https://book.getfoundry.sh/reference/forge/forge-create.html)

## Rinkeby

```bash
yarn deploy-rinkeby
```

## Mainnet

```bash
yarn deploy-mainnet
```

The deployments are stored in ./broadcast
