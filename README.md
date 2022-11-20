# aptos-staking

## prerequisites

### move

- install Just https://github.com/casey/just

## develop locally

- Run `aptos node run-local-testnet --with-faucet`
- Create a coin: https://aptos.dev/tutorials/your-first-coin/
- Create an NFT: https://aptos.dev/tutorials/your-first-nft/

- Publish the packages:

  - Move to `move/` folder
  - Run `just publish queue`
  - Run `just publish farm`

- Move to `app/` and run `yarn`
- Run `yarn dev` to work locally
