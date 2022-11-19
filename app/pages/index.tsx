/** @jsxImportSource theme-ui */
import { WalletManager } from "@/components/WalletManager"
import { Button, Flex, Heading, Input } from "theme-ui"
import { Tab, TabList, TabPanel, Tabs } from "react-tabs"
import { CollectionList } from "@/components/CollectionList"
import { useState } from "react"
import { Nft } from "@/components/CollectionItem"

export default function Home() {
  const [selectedWalletItems, setSelectedWalletItems] = useState<Nft[]>([])
  const [selectedVaultItems, setSelectedVaultItems] = useState<Nft[]>([])

  const walletNFTs = []

  /**
   * Handles selected items.
   */
  const handleWalletItemClick = (item: Nft) => {
    setSelectedWalletItems((prev) => {
      const exists = prev.find(
        (NFT) => NFT.onchainMetadata.mint === item.onchainMetadata.mint
      )

      /** Remove if exists */
      if (exists) {
        return prev.filter(
          (NFT) => NFT.onchainMetadata.mint !== item.onchainMetadata.mint
        )
      }

      return prev.length < 4 ? prev?.concat(item) : prev
    })
  }

  const handleVaultItemClick = (item: NFT) => {
    setSelectedVaultItems((prev) => {
      const exists = prev.find(
        (NFT) => NFT.onchainMetadata.mint === item.onchainMetadata.mint
      )

      /** Remove if exists */
      if (exists) {
        return prev.filter(
          (NFT) => NFT.onchainMetadata.mint !== item.onchainMetadata.mint
        )
      }

      return prev.length < 4 ? prev?.concat(item) : prev
    })
  }

  return (
    <>
      <main
        sx={{
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          alignItems: "center",
          maxWidth: "64rem",
          margin: "0 auto",
          marginTop: "4rem",
        }}
      >
        <Flex
          sx={{
            justifyContent: "space-between",
            alignItems: "center",
            gap: "3.2rem",
            alignSelf: "stretch",
          }}
        >
          <Heading mb=".8rem" variant="heading1">
            Aptos Staking
          </Heading>
          <WalletManager />
        </Flex>

        <Flex
          my="3.2rem"
          sx={{
            flexDirection: "column",
            gap: "1.6rem",
            alignSelf: "stretch",
          }}
        >
          <Tabs
            sx={{
              margin: "3.2rem 0",
              alignSelf: "stretch",
              minHeight: "48rem",
            }}
          >
            <TabList>
              <Tab>Your wallet</Tab>
              <Tab>Your vault</Tab>
            </TabList>

            <TabPanel>
              <Flex
                sx={{
                  alignItems: "center",
                  justifyContent: "space-between",
                  margin: "1.6rem 0",
                  paddingBottom: ".8rem",
                }}
              >
                <Heading variant="heading2">Your wallet NFTs</Heading>
                <Button
                  onClick={async (e) => {
                    // const allMints = selectedWalletItems.map(
                    //   (item) => item.mint
                    // )
                    // await stakeAll(allMints)
                    // await fetchNFTs()
                    // await fetchReceipts()
                    // setSelectedWalletItems([])
                  }}
                  // disabled={!selectedWalletItems.length}
                >
                  Stake selected
                </Button>
              </Flex>

              <CollectionList NFTs={walletNFTs}>
                <>
                  {walletNFTs?.map((item) => {
                    const isSelected = selectedWalletItems.find(
                      (NFT) =>
                        NFT.onchainMetadata.mint === item.onchainMetadata.mint
                    )

                    return (
                      <Flex
                        sx={{
                          flexDirection: "column",
                          alignItems: "center",
                          gap: "1.6rem",
                        }}
                      >
                        <CollectionItem
                          key={item.onchainMetadata.mint}
                          item={item}
                          onClick={handleWalletItemClick}
                          sx={{
                            maxWidth: "16rem",
                            "> img": {
                              border: "3px solid transparent",
                              borderColor: isSelected
                                ? "primary"
                                : "transparent",
                            },
                          }}
                        />
                      </Flex>
                    )
                  })}
                </>
              </CollectionList>
            </TabPanel>

            <TabPanel>
              <Flex
                sx={{
                  alignItems: "center",
                  justifyContent: "space-between",
                  margin: "1.6rem 0",
                  paddingBottom: ".8rem",
                }}
              >
                <Heading variant="heading2">Your vault NFTs</Heading>
                <Button
                  onClick={async (e) => {
                    const allMints = selectedVaultItems.map((item) => item.mint)
                    await unstakeAll(allMints)
                    await fetchNFTs()
                    await fetchReceipts()
                    setSelectedVaultItems([])
                  }}
                  disabled={!selectedVaultItems.length}
                >
                  Unstake selected
                </Button>
              </Flex>
              <Flex
                sx={{
                  flexDirection: "column",
                  gap: "1.6rem",

                  "@media (min-width: 768px)": {
                    display: "grid",
                    gridTemplateColumns: "1fr 1fr 1fr 1fr",
                  },
                }}
              >
                {orderedReceipts &&
                  orderedReceipts.map((stake) => {
                    const isSelected = selectedVaultItems.find(
                      (NFT) =>
                        NFT.onchainMetadata.mint ===
                        stake.metadata.onchainMetadata.mint
                    )

                    return (
                      <Flex
                        sx={{
                          flexDirection: "column",
                          alignItems: "center",
                          gap: "1.6rem",
                        }}
                      >
                        <CollectionItem
                          sx={{
                            maxWidth: "16rem",
                            "> img": {
                              border: "3px solid transparent",
                              borderColor: isSelected
                                ? "primary"
                                : "transparent",
                            },
                          }}
                          // onClick={handleVaultItemClick}
                          // item={stake.metadata}
                        />
                        {/* <Flex
                                sx={{
                                  gap: "1.6rem",
                                  alignItems: "center",
                                  flexDirection: "column",
                                  marginTop: "1.6rem",
                                }}
                              >
                                <Button variant="resetted">Unstake</Button>
                              </Flex> */}
                      </Flex>
                    )
                  })}
              </Flex>
            </TabPanel>
          </Tabs>
        </Flex>
      </main>
    </>
  )
}
