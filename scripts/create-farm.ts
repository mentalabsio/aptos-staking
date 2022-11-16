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
const modulePublisherAddress =
  "0xb31a6b65ef781be729ea190e78f3050cb74d5db752ab729f603f594e1a3f7b63"

/** Account to sign for the farm on-chain resource. */
const farmOwnerAccount = new AptosAccount(
  new HexString(
    "0x951199b8d721130dac46809cc5ae177eede6eb4850478b80829985b90c57576d"
  ).toUint8Array()
)
console.log("farmOwnerAccount", farmOwnerAccount.address().toString())

/** Module for the coin used in staking */
const coinTypeAddress =
  "0xfeda4efea5e23ed95c461f92f7103f2032c6a06f9792b0eb91d8ac38ddd4bcd9::moon_coin::MoonCoin"

const farmAddress = getResourceAccountAddress(
  farmOwnerAccount.address(),
  Buffer.from("farm")
)

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

  try {
    // await createFarm()
    // await addToWhitelist()
  } catch (e) {
    console.log(e)
  }
})()
