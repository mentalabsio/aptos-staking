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
    const result = (await client.waitForTransactionWithResult(tx.hash)) as any

    console.log("success", result.success)
    console.log("vm_status", result.vm_status)
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
    // await addToWhitelist()
    await fundReward()
  } catch (e) {
    console.log(e)
  }
})()
