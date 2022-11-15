import { AptosAccount, AptosClient, HexString } from "aptos"

/**
 * Runs farm commands against the published module
 */
;(async () => {
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

    const resources = await client.getAccountResources(
      farmOwnerAccount.address()
    )

    console.log(resources)

    const rsrc = await client.getAccountResource(
      farmOwnerAccount.address(),
      "0x1::account::Account"
    )

    console.log(rsrc)
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
    await createFarm()
    // await addToWhitelist()
  } catch (e) {
    console.log(e)
  }
})()
