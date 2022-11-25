/** @jsxImportSource theme-ui */

import { useWallet } from "@manahippo/aptos-wallet-adapter"
import { Flex, Spinner, Text } from "@theme-ui/components"
import { Nft } from "./CollectionItem"

export type NFTCollectionProps = {
  NFTs: Nft[]
  children?: React.ReactChild
}

/**
 * Component to displays all NFTs from a connected wallet
 */
export function CollectionList({ NFTs, children }: NFTCollectionProps) {
  const { account } = useWallet()

  return (
    <>
      {NFTs ? (
        NFTs.length ? (
          <div
            sx={{
              display: "grid",
              gridTemplateColumns: "1fr 1fr",
              gap: "1.6rem",
              alignItems: "center",

              "@media (min-width: 768px)": {
                gridTemplateColumns: "1fr 1fr 1fr 1fr",
              },
            }}
          >
            {children}
          </div>
        ) : (
          /** NFTs fetched but array is empty, means current wallet has no NFT. */
          <Flex
            sx={{
              justifyContent: "center",
              alignSelf: "stretch",
            }}
          >
            <Text>There are no Bored Aptos in your wallet.</Text>
          </Flex>
        )
      ) : /** No NFTs and public key, means it is loading */
      account ? (
        <Flex
          sx={{
            justifyContent: "center",
            alignSelf: "stretch",
          }}
        >
          <Spinner
            sx={{
              width: "4rem",
            }}
          />
        </Flex>
      ) : (
        <Text>Connect your wallet first.</Text>
      )}
    </>
  )
}
