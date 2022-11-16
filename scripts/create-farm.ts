import {
  AptosAccount,
  AptosClient,
  BCS,
  HexString,
  MaybeHexString,
  TxnBuilderTypes,
} from "aptos"
import { sha3_256 as sha3Hash } from "@noble/hashes/sha3"

const getResourceAccountAddress = (
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

  const hash = sha3Hash.create()
  hash.update(originBytes)

  return HexString.fromUint8Array(hash.digest())
}

/** Address which published the farm module. */
const modulePublisherAddress = ""

/** Account that will own the farm on-chain resources. */
const farmOwnerAccount = new AptosAccount(new HexString("").toUint8Array())
console.log("farmOwnerAccount", farmOwnerAccount.address().toString())

/** Module for the coin used in staking */
const coinTypeAddress =
  "0x92613d7ccde977d947e68d9858a0e2f4bbddc04e9dfa36473597ecb95f9aab1a::moon_coin::MoonCoin"

const farmAddress = getResourceAccountAddress(
  farmOwnerAccount.address(),
  Buffer.from("farm")
).hex()

/**
 * Runs farm commands against the published module
 */
;(async () => {
  const client = new AptosClient("http://0.0.0.0:8080")

  const createFarm = async () => {
    const payload = {
      type: "entry_function_payload",
      function: `${modulePublisherAddress}::farm::publish_farm`,
      type_arguments: [`${coinTypeAddress}`],
      arguments: [],
    }

    const rawTx = await client.generateTransaction(
      farmOwnerAccount.address(),
      payload
    )

    const signedTX = await client.signTransaction(farmOwnerAccount, rawTx)
    const tx = await client.submitTransaction(signedTX)
    const result = await client.waitForTransactionWithResult(tx.hash)

    console.log(result)
  }

  const addToWhitelist = async () => {
    const payload = {
      type: "entry_function_payload",
      function: `${modulePublisherAddress}::farm::add_to_whitelist`,
      type_arguments: [`${coinTypeAddress}`],
      arguments: ["Alice's", 1],
    }

    const rawTx = await client.generateTransaction(
      farmOwnerAccount.address(),
      payload
    )

    const signedTX = await client.signTransaction(farmOwnerAccount, rawTx)
    const tx = await client.submitTransaction(signedTX)
    const result = await client.waitForTransactionWithResult(tx.hash)

    console.log(result)
  }

  const stake = async () => {
    const collectionName = "Alice's"
    const tokenName = "Alice's first token"
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
    const result = await client.waitForTransactionWithResult(tx.hash)

    console.log(result)
  }

  try {
    // await createFarm()
    // await addToWhitelist()
    await stake()
  } catch (e) {
    console.log(e)
  }
})()
