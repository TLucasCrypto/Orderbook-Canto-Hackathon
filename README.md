# Canto Decentralized Orderbook

This repository is a submission for the Canto Online Hackathon season 2.

## Canto

The intention behind this orderbook is to eventually add it, or a version of it, to Canto's existing Free Public Infrastructure. The orderbook takes no fees from makers nor takers, and any EOA or protocol can add to and buy from the orderbook.

Canto is uniquely positioned due to its identity as a DeFi idealist blockchain to support a blockchain wide orderbook which is accessable, transparent, decentralized, and free for all. A blockchain wide orderbook which can be used by any user or protocol on the Canto network.

One of the major problems with current orderbooks are that they are highly fragmented. An orderbook run by Coinbase cannot interact with an orderbook run by Binance, and the liquidity is halved. Protocols are incentivized to keep their own orderbooks to profit off the exorbitant fees, but doing so degrades user experience. Some protocols try to bridge this gap by aggregating different exchanges and finding the best prices for your tokens, but this is inefficient and costly. 

This project is permissionless, and anyone can use it to trade any ERC20 tokens. Technically, any token can be listed on the orderbook as long as it has functions for transfer(address,uint256), transferFrom(address,address,uint256), and balanceOf(address). It is not advised to use non-fungible tokens with the ordrerbook in its current state, but could potentially be added if needed. A second non-fungible deployment is a more realistic option.

As this project will be deployed on Canto, I would love feedback from the Canto community. 

## Introduction 

### Orderbooks
Orderbooks are a common tool used in finance to facilitate user transactions. They use a sorted list of maker orders for specific token pairs to match users who are trying to trade one token for another. Most exchanges use the orderbook model as they allow for consistent transactions, and can allow for more complex order types. 

Most orderbooks in use today are heavily centralized entities with little transparency or assurance of their inner workings. The opaque manner in which they are run creates concerns about their "fairness" such that they may create fake volume and engage in price manipulation or insider trading. A decentralized orderbook where all orders are written onto the blockchain allows for transparent trading while maintaining many of the benefits of the orderbook model. 


### Automated Market Makers
Canto already has an AMM in the free public infrastructure, so should a public decentralized orderbook even exist? The AMM model is an innovative method in which to allow for freely accessable, decentralized transactions between token pairs. AMMs process all transactions automatically, without relying on third party buy/sell requests for the token being traded. This system has its benefits, but it also has its drawbacks. Some of the drawbacks of the AMM model include slippage, liquidity fragmentation, impermanent loss, and only supports simple order types. If you want to create a limit order, or have your order expire after a certain timelimit you are basically out of luck. Additionally, liquidity providers must supply liquidity for each supported token pair, and if a pair has little liquidity, traders can severly unbalance the pools creating significant losses.

## Code

### PublicMarket.sol
This contract contains the main functions that can be called by users. These funcitons include makeOfferSimple/makeOfferExpiry, cancelOffer, marketBuy, withdraw, withdrawMany, and getItems.

#### makeOfferSimple/makeOfferExpiry
These functions are used to create an order in the orderbook. The difference is that makeOfferSimple creates an order that will not (effectively) expire, whereas makeOfferExpiry creates an order that has a deadline. These both invoke the _makeOffer function which will first attempt to fill the order from the reversed token pair, and any unpurchased funds will turn into an order in the orderbook. These functions require the user to approve the market to transfer the input pay_amount of pay_token, which will be transfered to the market until the order is filled or canceled.

#### cancelOffer
This function allows the account that created the order the ability to cancel the order they created and will return the funds from the order and any additional balance the user may have for that token.

#### marketBuy
Very similar to the makeOfferSimple function, except that it will return to the user any funds that were remain after trying to buy orders from the orderbook. Reverts if no tokens are purchased.

#### withdraw
The withdraw function lets users claim their tokens from filled orders. When an order is filled, the user's balance in the userBalance mapping is updated, and will remain in the contract until it is withdrawn through one of the withdraw functions or through a function which calls _sendFunds for that token.

#### withdrawMany
This function allows the user to withdraw their balance of multiple token addresses. As the user's balance is seperate for each token address, this allows for easier withdrawls when the user has multiple tokens to withdraw. 

#### getItems
This is a function to retrieve the lowest priced orders for a token pair. 

### MatchingEngine.sol
This contract contains the logic for matching and filling orders. 

#### Filling Orders
Orders are filled though the _marketBuy and _processBuy functions. These functions will attempt to fill the lowest price order in a market until the price exceeds the required limit or the provided funds are used up.  

#### Offer Validation
There are currently only two types of orders: limit orders and expiry orders. Validation only occurs on the latter type, and if the block.timestamp has exceeded the expiry time, the logic will delete the order prior to being purchased. This means that expired orders are still visible in the orderbook until they are either canceled, or an action attempts to consume them like a marketBuy. Orders removed will update their owner's balance for pay_token.

There is another method for order validation which is explained in the OffersLib section.

### SimpleMarket.sol
This contract contains the basic logic and state variables of the orderbook. Most important to note are the use of the OffersLib and StructuredLinkedList libraries. 

#### OffersLib
A custom library containing useful operations for individual orders.

A different version of OffersLib is found in the experimental folder of this repo. The experimental folder contains contracts from a different implementation of this repo, and used src/Experimental/OffersLib.sol and src/Experimental/Validator.sol. The original implementation has been moved to the experimental folder and used orders with a bytes data field instead of the uint48 expiry. This allowed for the creation of an upgradeable validator contract while the market contract was immutable. This would allow for upgrading soley the validator contract to add additional complex order types based on the bytes data  passed in to the order. I ended up only having two types of orders, and the added complexity and gas costs did not make sense, so the validation just moved into MatchingEngine.sol. The experimental versions are still included if this type of functionality is desired by the community, and can be added back in. 

#### StructuredLinkedList.sol
A library written by Vittorio Minacori (https://github.com/vittominacori). "An utility library for working with sorted linked list data structures in your Solidity project." This is the main data structure for each orderbook. It is slightly modified from the original, specifically the getSortedSpot function to sort in order of increasing price. This library uses the IStructureInterface to determine sort order, and ends up calling back into this orderbook contract's getValue function.


## Dev Notes
The orderbook is in a working state, and has been tested moderately. The testing includes, but is not limited to, the tests included in this repo. Due to a refactor of the contracts, many of the tests I had written were unable to be included in the updated codebase. A project like this must undergo much more rigorous and formal testing/auditing before being put on mainnet for users to interact with.  