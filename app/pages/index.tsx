/** @jsxImportSource theme-ui */
import { WalletManager } from "@/components/WalletManager"
import { Button, Flex, Heading, Input, Text } from "theme-ui"
import { Tab, TabList, TabPanel, Tabs } from "react-tabs"
import { CollectionList } from "@/components/CollectionList"
import { useState } from "react"
import CollectionItem, { Nft } from "@/components/CollectionItem"
import { useWallet } from "@manahippo/aptos-wallet-adapter"
import { useTokens } from "@/hooks/useTokens"
import { useStaking } from "@/hooks/useStaking"

export default function Home() {
  const [selectedWalletItems, setSelectedWalletItems] = useState<Nft[]>([])
  const [selectedVaultItems, setSelectedVaultItems] = useState<Nft[]>([])
  const { account } = useWallet()
  const {
    claim,
    stake,
    unstake,
    bankTokens,
    rewardVaultData,
    totalNftStaked,
    fetchBankTokens,
  } = useStaking()

  const { tokens, fetchTokens } = useTokens(
    account?.address?.toString(),
    null,
    "The Bored Aptos Yacht Club"
  )

  /**
   * Handles selected items.
   */
  const handleWalletItemClick = (item: Nft) => {
    setSelectedWalletItems((prev) => {
      const exists = prev.find((NFT) => NFT.name === item.name)

      /** Remove if exists */
      if (exists) {
        return prev.filter((NFT) => NFT.name !== item.name)
      }

      return prev.length < 1 ? prev?.concat(item) : prev
    })
  }

  const handleVaultItemClick = (item: Nft) => {
    setSelectedVaultItems((prev) => {
      const exists = prev.find((NFT) => NFT.name === item.name)

      /** Remove if exists */
      if (exists) {
        return prev.filter((NFT) => NFT.name !== item.name)
      }

      return prev.length < 1 ? prev?.concat(item) : prev
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
          padding: "0 1.6rem",
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
          <img
            sx={{
              maxWidth: "8rem",
            }}
            src="/boredaptos.png"
          />
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
          <Flex
            sx={{
              background: "#1E1E1E",
              padding: "3.2rem 1.6rem",
              justifyContent: "center",

              flexDirection: "column",
              gap: "1.6rem",
              borderRadius: ".4rem",

              "@media (min-width: 768px)": {
                flexDirection: "row",
                gap: "4.8em",
              },
            }}
          >
            <Flex
              sx={{
                flexDirection: "column",
                alignItems: "center",
              }}
            >
              <Text>NFTs staked</Text>
              <Text
                sx={{
                  background:
                    "linear-gradient(90deg, #FBEF75 2.95%, #FED4D5 17.93%, #FC98E8 30%, #95D2F9 46.91%, #B2F5EB 61.41%, #7BFBAD 79.77%, #64FF67 95.71%)",
                  backgroundClip: "text",
                  textFillColor: "transparent",
                  fontSize: "2.2rem",
                }}
              >
                {totalNftStaked ? totalNftStaked : "..."}
              </Text>
            </Flex>
            {/* <Flex
              sx={{
                flexDirection: "column",
                alignItems: "center",
              }}
            >
              <Text>Estimated Rewards</Text>
              <Text
                sx={{
                  background:
                    "linear-gradient(90deg, #FBEF75 2.95%, #FED4D5 17.93%, #FC98E8 30%, #95D2F9 46.91%, #B2F5EB 61.41%, #7BFBAD 79.77%, #64FF67 95.71%)",
                  backgroundClip: "text",
                  textFillColor: "transparent",
                  fontSize: "2.2rem",
                }}
              >
                {tokens ? tokens.length * 20 : "..."}
                $APETOS
              </Text>
            </Flex> */}
            <Flex
              sx={{
                flexDirection: "column",
                alignItems: "center",
              }}
            >
              <Text>Reward Rate</Text>
              <Text
                sx={{
                  background:
                    "linear-gradient(90deg, #FBEF75 2.95%, #FED4D5 17.93%, #FC98E8 30%, #95D2F9 46.91%, #B2F5EB 61.41%, #7BFBAD 79.77%, #64FF67 95.71%)",
                  backgroundClip: "text",
                  textFillColor: "transparent",
                  fontSize: "2.2rem",
                }}
              >
                20 $APETOS/day
              </Text>
            </Flex>
          </Flex>
          {account?.address ? (
            <Button
              sx={{
                alignSelf: "center",
              }}
              onClick={async () => {
                await claim()
              }}
            >
              Claim
            </Button>
          ) : null}

          {/* {rewardVaultData?.available} <br />
          {} */}
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
                    console.log(selectedWalletItems)
                    const collectionName = selectedWalletItems[0].collection
                    const tokenName = selectedWalletItems[0].name

                    try {
                      await stake({ collectionName, tokenName })

                      await fetchTokens()
                      await fetchBankTokens()

                      setSelectedWalletItems([])
                    } catch (e) {
                      console.log(e)
                    }
                  }}
                  disabled={!selectedWalletItems.length}
                >
                  Stake selected
                </Button>
              </Flex>

              <CollectionList NFTs={tokens}>
                <>
                  {tokens?.map((item) => {
                    const isSelected = selectedWalletItems.find(
                      (NFT) => NFT.name === item.name
                    )

                    return (
                      <Flex
                        key={item.name}
                        sx={{
                          flexDirection: "column",
                          alignItems: "center",
                          gap: "1.6rem",
                        }}
                      >
                        <CollectionItem
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
                    const collectionName = selectedVaultItems[0].collection
                    const tokenName = selectedVaultItems[0].name

                    try {
                      await unstake({ collectionName, tokenName })
                      await fetchBankTokens()
                      await fetchTokens()
                      setSelectedVaultItems([])
                    } catch (e) {
                      console.log(e)
                    }
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
                {bankTokens &&
                  bankTokens.map((item) => {
                    const isSelected = selectedVaultItems.find(
                      (NFT) => NFT.name === item.name
                    )

                    return (
                      <Flex
                        key={item.name}
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
                          onClick={handleVaultItemClick}
                          item={item}
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
        <Flex
          sx={{
            gap: "3.2rem",
            margin: "3.2rem 0 1.6rem 0",

            fontSize: "2rem",

            a: {
              color: "#7B7B7B",
            },
          }}
        >
          <a
            href="https://boredaptos.medium.com/the-bored-aptos-story-79aaf355c9ab"
            target="_blank"
            rel="noopener noreferrer"
          >
            What is $APETOS?
          </a>
          <a
            href="https://www.topaz.so/collection/The-Bored-Aptos-Yacht-Club-97d8291b05"
            target="_blank"
            rel="noopener noreferrer"
          >
            Topaz Market
          </a>
        </Flex>
      </main>
    </>
  )
}
