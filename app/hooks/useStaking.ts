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
import { useEffect, useState } from "react"

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

/** Address which published the farm module, and also the coin module. Also this account should own the farm. */
export const modulePublisherAddress =
  "0x52582b2b41e43a956e632d2f6f8ed98d15a580ea207ca488af4b118c91156d93"

/** Module for the coin used in staking */
export const coinTypeAddress = `${modulePublisherAddress}::moon_coin::MoonCoin`

export const farmAddress = getResourceAccountAddress(
  modulePublisherAddress,
  Buffer.from("farm")
).hex()

type RewardVaultData = {
  available: string
  debt_queue: { inner: Array<unknown> }
  num_receivers: string
  reward_rate: string
}

type RewardAccountResource = {
  data: RewardVaultData
}

export const useStaking = () => {
  const client = new AptosClient("http://0.0.0.0:8080")
  const { account, signAndSubmitTransaction } = useWallet()
  const [rewardVaultData, setRewardVaultData] =
    useState<RewardVaultData | null>(null)

  const bankAddress = account?.address?.toString()
    ? getResourceAccountAddress(
        account?.address?.toString(),
        Buffer.from("bank")
      )
    : ""

  const { tokens: bankTokens } = useTokens(bankAddress.toString())

  useEffect(() => {
    ;(async () => {
      const rewardTransmitterAddress = getResourceAccountAddress(
        farmAddress,
        Buffer.from("transmitter")
      )

      console.log(rewardTransmitterAddress.toString())

      // @ts-ignore
      const { data } = (await client.getAccountResource(
        rewardTransmitterAddress,
        `${modulePublisherAddress}::reward_vault::RewardTransmitter<${coinTypeAddress}>`
      )) as RewardAccountResource

      setRewardVaultData(data)
    })()
  }, [])

  useEffect(() => {
    ;(async () => {
      if (account?.address) {
        // @ts-ignore
        const rewardReceiverResources = await client.getAccountResource(
          account?.address.toString(),
          `${modulePublisherAddress}::reward_vault::RewardReceiver<${coinTypeAddress}>`
        )

        const {
          data: {
            // @ts-ignore
            vaults: { handle: vault },
          },
        } = rewardReceiverResources
        console.log(rewardReceiverResources)
      }
    })()
  }, [account])

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
        modulePublisherAddress,
        collectionName,
        tokenName,
        tokenPropertyVersion,
        farmAddress,
      ],
    }

    const tx = await signAndSubmitTransaction(payload)
    const result = (await client.waitForTransactionWithResult(tx.hash)) as any

    console.log("success", result.success)
    console.log("vm_status", result.vm_status)
  }

  const unstake = async ({
    collectionName,
    tokenName,
  }: {
    collectionName: string
    tokenName: string
  }) => {
    const tokenPropertyVersion = 0

    const payload = {
      type: "entry_function_payload",
      function: `${modulePublisherAddress}::farm::unstake`,
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
        modulePublisherAddress,
        collectionName,
        tokenName,
        tokenPropertyVersion,
        farmAddress,
      ],
    }

    const tx = await signAndSubmitTransaction(payload)
    const result = (await client.waitForTransactionWithResult(tx.hash)) as any

    console.log("success", result.success)
    console.log("vm_status", result.vm_status)
  }

  const claim = async () => {
    const payload = {
      type: "entry_function_payload",
      function: `${modulePublisherAddress}::farm::claim_rewards`,
      type_arguments: [`${coinTypeAddress}`],
      /**
       * Arguments:
       *
       * farm: address
       */
      arguments: [farmAddress],
    }

    const tx = await signAndSubmitTransaction(payload)
    const result = (await client.waitForTransactionWithResult(tx.hash)) as any

    console.log("success", result.success)
    console.log("vm_status", result.vm_status)
  }

  return { claim, stake, unstake, bankTokens, rewardVaultData }
}
