import { AccountKeys } from "@manahippo/aptos-wallet-adapter"
import { useEffect, useState } from "react"
import { WalletClient } from "@martiandao/aptos-web3-bip44.js"

// export const APTOS_NODE_URL =
//   "https://aptos-mainnet.nodereal.io/v1/5f41e22184804070bc3ea2b77f0809d9/v1/"
// export const APTOS_FAUCET_URL = "https://faucet.devnet.aptoslabs.com/v1/"

export const APTOS_NODE_URL =
  "https://aptos-mainnet.nodereal.io/v1/5f41e22184804070bc3ea2b77f0809d9/v1"
export const APTOS_FAUCET_URL = "http://0.0.0.0:8081"

export const walletClient = new WalletClient(APTOS_NODE_URL, APTOS_FAUCET_URL)

export interface Token {
  propertyVersion: number
  creator: string
  collection: string
  name: string
  description: string
  uri: string
  maximum: number
  supply: number
}

type TokenId = {
  data: {
    property_version: any
    token_data_id: {
      collection: string
      creator: string
      name: string
    }
  }
  difference: number
}

export const getTokens = async (
  address: string,
  /** Filter by creator */
  creator?: string,
  /** Filter by collection */
  collection?: string
) => {
  const data: {
    tokenIds: TokenId[]
    maxDepositSequenceNumber: number
    maxWithdrawSequenceNumber: number
  } = await walletClient.getTokenIds(address.toString(), 100, 0, 0)

  let tokenIds = data.tokenIds.filter((tokenId) => tokenId.difference != 0)

  if (creator) {
    tokenIds = tokenIds.filter(
      (tokenId) => tokenId.data.token_data_id.creator === creator
    )
  }

  if (collection) {
    tokenIds = tokenIds.filter(
      (tokenId) => tokenId.data.token_data_id.collection === collection
    )
  }

  const tokens = tokenIds.map(async (i) => {
    const token = await walletClient.getToken(i.data)

    return {
      propertyVersion: i.data.property_version,
      creator: i.data.token_data_id.creator,
      collection: token.collection,
      name: token.name,
      description: token.description,
      uri: token.uri,
      maximum: token.maximum,
      supply: token.supply,
    }
  })

  return await Promise.all(tokens)
}

export function useTokens(
  address: string | null,
  /** Filter by creator */
  creator?: string,
  /** Filter by collection */
  collection?: string
): {
  tokens: Token[]
  loading: boolean
} {
  const [tokens, setTokens] = useState<Token[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (address) {
      ;(async () => {
        const tokens = await getTokens(address, creator, collection)
        setLoading(false)
        setTokens(tokens)
      })()
    }
  }, [address])

  return { tokens, loading }
}
