# forgeup

Update or revert to a specific [Foundry](https://github.com/gakonst/foundry) commit with ease.

## Installing

```sh
curl http://xn--2-kmb.com/forgeup/install | bash
```

## Using

To install the **latest** commit:

```sh
forgeup
```

To install a specific **branch** (in this case the `release/0.1.0` branch's latest commit):

```sh
forgeup release/0.1.0
```

To install a **fork's main branch** (in this case `transmissions11/foundry`'s main branch):

```sh
forgeup transmissions11/foundry
```

To install a **specific branch in a fork** (in this case the `foundry` branch's latest commit in `transmissions11/dapptools`):

```sh
forgeup transmissions11/foundry patch-10
```
