import { AptosAccount, AptosClient, HexString } from "aptos"
import {
  coinTypeAddress,
  modulePublisherAddress,
} from "../app/hooks/useStaking"

const farmOwnerAccount = new AptosAccount(new HexString("").toUint8Array())

/**
 * Runs farm commands against the published module
 */
;(async () => {
  const client = new AptosClient(
    "https://aptos-mainnet.nodereal.io/v1/5f41e22184804070bc3ea2b77f0809d9/v1"
  )

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
    const result = (await client.waitForTransactionWithResult(tx.hash)) as any

    console.log(result)
    console.log("success", result.success)
    console.log("vm_status", result.vm_status)
  }

  const addToWhitelist = async () => {
    const payload = {
      type: "entry_function_payload",
      function: `${modulePublisherAddress}::farm::add_to_whitelist`,
      type_arguments: [`${coinTypeAddress}`],
      /**
       * arguments:
       *
       * collection name
       * reward per second
       */
      arguments: ["The Bored Aptos Yacht Club", 0.000231e6],
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

  const fundReward = async () => {
    const payload = {
      type: "entry_function_payload",
      function: `${modulePublisherAddress}::farm::fund_reward`,
      type_arguments: [`${coinTypeAddress}`],
      // arg: amount
      arguments: [10e6],
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

  try {
    // await createFarm()
    await addToWhitelist()
    // await fundReward()
  } catch (e) {
    console.log(e)
  }
})()
