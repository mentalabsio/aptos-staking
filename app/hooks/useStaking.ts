import {
  AptosAccount,
  AptosClient,
  BCS,
  HexString,
  MaybeHexString,
  TxnBuilderTypes,
} from "aptos"
import { sha3_256 } from "@noble/hashes/sha3"
import { useWallet } from "@manahippo/aptos-wallet-adapter"
import { useTokens } from "./useTokens"

export const getResourceAccountAddress = (
  sourceAddress: MaybeHexString,
  seed: Uint8Array
) => {
  const source = BCS.bcsToBytes(
    TxnBuilderTypes.AccountAddress.fromHex(sourceAddress)
  )

  const originBytes = new Uint8Array(source.length + seed.length + 1)

  originBytes.set(source)
  originBytes.set(seed, source.length)
  originBytes.set([255], source.length + seed.length)

  const hash = sha3_256.create()
  hash.update(originBytes)

  return HexString.fromUint8Array(hash.digest())
}

/** Account that will own the farm on-chain resources. */
export const farmOwnerAccount = new AptosAccount(
  new HexString("").toUint8Array()
)

/** Address which published the farm module, and also the coin module. */
export const modulePublisherAddress = farmOwnerAccount.address().toString()

console.log("farmOwnerAccount", farmOwnerAccount.address().toString())

/** Module for the coin used in staking */
export const coinTypeAddress = `${modulePublisherAddress}::moon_coin::MoonCoin`

export const farmAddress = getResourceAccountAddress(
  farmOwnerAccount.address(),
  Buffer.from("farm")
).hex()

export const useStaking = () => {
  const client = new AptosClient("http://0.0.0.0:8080")
  const { account } = useWallet()

  const bankAddress = account?.address?.toString()
    ? getResourceAccountAddress(
        account?.address?.toString(),
        Buffer.from("bank")
      )
    : ""

  const { tokens: bankTokens } = useTokens(bankAddress.toString())

  const stake = async ({
    collectionName,
    tokenName,
  }: {
    collectionName: string
    tokenName: string
  }) => {
    const tokenPropertyVersion = 0

    const payload = {
      type: "entry_function_payload",
      function: `${modulePublisherAddress}::farm::stake`,
      type_arguments: [`${coinTypeAddress}`],
      /**
       * Arguments:
       *
       * creator_address: address,
       * collection_name: String,
       * token_name: String,
       * property_version: u64,
       * farm: address
       */
      arguments: [
        farmOwnerAccount.address().toString(),
        collectionName,
        tokenName,
        tokenPropertyVersion,
        farmAddress,
      ],
    }

    const rawTx = await client.generateTransaction(
      farmOwnerAccount.address(),
      payload
    )

    const signedTX = await client.signTransaction(farmOwnerAccount, rawTx)
    const tx = await client.submitTransaction(signedTX)
    const result = (await client.waitForTransactionWithResult(tx.hash)) as any

    console.log("success", result.success)
    console.log("vm_status", result.vm_status)
  }

  return { stake, bankTokens }
}
