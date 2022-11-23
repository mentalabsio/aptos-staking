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
import { toast } from "react-hot-toast"

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
  "0x69c1b21fc28610043a57412568fd28d4199c0f57f90b1af8f687ec7fcc4ddd46"

/** Module for the coin used in staking */
export const coinTypeAddress = `${modulePublisherAddress}::apetos_coin::ApetosCoin`

export const farmAddress = getResourceAccountAddress(
  modulePublisherAddress,
  Buffer.from("farm")
).hex()

const creatorAddress =
  "0x97d8291b05b5438b0976b93554074f933608a491d63dcb2cfec368d6777631ef"

type RewardVaultData = {
  available: string
  debt_queue: { inner: Array<unknown> }
  num_receivers: string
  reward_rate: string
}

type RewardAccountResource = {
  data: RewardVaultData
}

const client = new AptosClient(
  "https://aptos-mainnet.nodereal.io/v1/5f41e22184804070bc3ea2b77f0809d9/v1"
)

export const useStaking = () => {
  const { account, signAndSubmitTransaction } = useWallet()
  const [rewardVaultData, setRewardVaultData] =
    useState<RewardVaultData | null>(null)

  const bankAddress = account?.address?.toString()
    ? getResourceAccountAddress(
        account?.address?.toString(),
        Buffer.from("bank")
      )
    : null

  const { tokens: bankTokens, fetchTokens: fetchBankTokens } = useTokens(
    bankAddress?.toString()
  )

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
        // const rewardReceiverResources = await client.getAccountResource(
        //   account?.address.toString(),
        //   `${modulePublisherAddress}::reward_vault::RewardReceiver<${coinTypeAddress}>`
        // )
        // const {
        //   data: {
        //     // @ts-ignore
        //     vaults: { handle: vault },
        //   },
        // } = rewardReceiverResources
        // console.log(rewardReceiverResources)
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
        creatorAddress,
        collectionName,
        tokenName,
        tokenPropertyVersion,
        farmAddress,
      ],
    }

    const toastId = toast.loading("Sending transaction...")

    try {
      const tx = await signAndSubmitTransaction(payload)
      const result = (await client.waitForTransactionWithResult(tx.hash)) as any

      toast.success("Success!", {
        id: toastId,
      })
      console.log("success", result.success)
      console.log("vm_status", result.vm_status)
    } catch (e) {
      toast.error("Something went wrong. " + e, {
        id: toastId,
      })
    }
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
        creatorAddress,
        collectionName,
        tokenName,
        tokenPropertyVersion,
        farmAddress,
      ],
    }

    const toastId = toast.loading("Sending transaction...")

    try {
      const tx = await signAndSubmitTransaction(payload)
      const result = (await client.waitForTransactionWithResult(tx.hash)) as any

      toast.success("Success!", {
        id: toastId,
      })
      console.log("success", result.success)
      console.log("vm_status", result.vm_status)
    } catch (e) {
      toast.error("Something went wrong. " + e, {
        id: toastId,
      })
    }
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

    const toastId = toast.loading("Sending transaction...")

    try {
      const tx = await signAndSubmitTransaction(payload)
      const result = (await client.waitForTransactionWithResult(tx.hash)) as any

      toast.success("Success!", {
        id: toastId,
      })
      console.log("success", result.success)
      console.log("vm_status", result.vm_status)
    } catch (e) {
      toast.error("Something went wrong. " + e, {
        id: toastId,
      })
    }
  }

  return { claim, stake, unstake, bankTokens, rewardVaultData, fetchBankTokens }
}
