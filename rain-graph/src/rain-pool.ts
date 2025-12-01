import {
  CancelBuyOrder as CancelBuyOrderEvent,
  CancelSellOrder as CancelSellOrderEvent,
  ChooseWinner as ChooseWinnerEvent,
  Claim as ClaimEvent,
  ClosePool as ClosePoolEvent,
  CreateOracle as CreateOracleEvent,
  CreatorClaim as CreatorClaimEvent,
  EnterLiquidity as EnterLiquidityEvent,
  EnterOption as EnterOptionEvent,
  ExecuteBuyOrder as ExecuteBuyOrderEvent,
  ExecuteSellOrder as ExecuteSellOrderEvent,
  PlaceBuyOrder as PlaceBuyOrderEvent,
  PlaceSellOrder as PlaceSellOrderEvent,
  PlatformClaim as PlatformClaimEvent,
  ResolverClaim as ResolverClaimEvent,
  ResolverSet as ResolverSetEvent,
  Sync as SyncEvent,
  OpenDispute as OpenDisputeEvent,
  RainTokenBurned as RainTokenBurnedEvent,
} from "../generated/templates/RainPool/RainPool"
import {
  CancelBuyOrder,
  CancelSellOrder,
  ChooseWinner,
  Claim,
  ClosePool,
  CreateOracle,
  CreatorClaim,
  EnterLiquidity,
  EnterOption,
  ExecuteBuyOrder,
  ExecuteSellOrder,
  PlaceBuyOrder,
  PlaceSellOrder,
  PlatformClaim,
  ResolverClaim,
  ResolverSet,
  Sync,
  OpenDispute,
  RainTokenBurned,
} from "../generated/schema"

import { ExternalSource } from '../generated/templates'

export function handleCancelBuyOrder(event: CancelBuyOrderEvent): void {
  let entity = new CancelBuyOrder(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.orderOption = event.params.orderOption
  entity.orderAmount = event.params.orderAmount
  entity.orderPrice = event.params.orderPrice
  entity.orderID = event.params.orderID
  entity.orderCreator = event.params.orderCreator

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.poolAddress = event.address

  entity.save()
}

export function handleCancelSellOrder(event: CancelSellOrderEvent): void {
  let entity = new CancelSellOrder(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.orderOption = event.params.orderOption
  entity.orderAmount = event.params.orderAmount
  entity.orderPrice = event.params.orderPrice
  entity.orderID = event.params.orderID
  entity.orderCreator = event.params.orderCreator

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.poolAddress = event.address

  entity.save()
}

export function handleChooseWinner(event: ChooseWinnerEvent): void {
  let entity = new ChooseWinner(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.winnerOption = event.params.winnerOption
  entity.platformShare = event.params.platformShare
  entity.liquidityShare = event.params.liquidityShare
  entity.winningShare = event.params.winningShare

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.poolAddress = event.address

  entity.save()
}

export function handleClaim(event: ClaimEvent): void {
  let entity = new Claim(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.wallet = event.params.wallet
  entity.winnerOption = event.params.winnerOption
  entity.liquidityReward = event.params.liquidityReward
  entity.reward = event.params.reward
  entity.totalReward = event.params.totalReward

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.poolAddress = event.address

  entity.save()
}

export function handleClosePool(event: ClosePoolEvent): void {
  let entity = new ClosePool(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.poolStatus = event.params.poolStatus

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.poolAddress = event.address

  entity.save()
}

export function handleCreateOracle(event: CreateOracleEvent): void {
  let entity = new CreateOracle(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.creatorContract = event.params.creatorContract
  entity.createdContract = event.params.createdContract

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.poolAddress = event.address

  entity.save()

  ExternalSource.create(event.params.createdContract);
}

export function handleCreatorClaim(event: CreatorClaimEvent): void {
  let entity = new CreatorClaim(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.wallet = event.params.wallet
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.poolAddress = event.address

  entity.save()
}

export function handleEnterLiquidity(event: EnterLiquidityEvent): void {
  let entity = new EnterLiquidity(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.baseAmount = event.params.baseAmount
  entity.wallet = event.params.wallet

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.poolAddress = event.address

  entity.save()
}

export function handleEnterOption(event: EnterOptionEvent): void {
  let entity = new EnterOption(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.option = event.params.option
  entity.baseAmount = event.params.baseAmount
  entity.optionAmount = event.params.optionAmount
  entity.wallet = event.params.wallet

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.poolAddress = event.address

  entity.save()
}

export function handleExecuteBuyOrder(event: ExecuteBuyOrderEvent): void {
  let entity = new ExecuteBuyOrder(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.orderOption = event.params.orderOption
  entity.orderPrice = event.params.orderPrice
  entity.optionAmount = event.params.optionAmount
  entity.baseAmount = event.params.baseAmount
  entity.orderID = event.params.orderID
  entity.maker = event.params.maker
  entity.taker = event.params.taker

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.poolAddress = event.address

  entity.save()
}

export function handleExecuteSellOrder(event: ExecuteSellOrderEvent): void {
  let entity = new ExecuteSellOrder(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.orderOption = event.params.orderOption
  entity.orderPrice = event.params.orderPrice
  entity.optionAmount = event.params.optionAmount
  entity.baseAmount = event.params.baseAmount
  entity.orderID = event.params.orderID
  entity.maker = event.params.maker
  entity.taker = event.params.taker

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.poolAddress = event.address

  entity.save()
}

export function handlePlaceBuyOrder(event: PlaceBuyOrderEvent): void {
  let entity = new PlaceBuyOrder(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.orderOption = event.params.orderOption
  entity.orderPrice = event.params.orderPrice
  entity.orderAmount = event.params.orderAmount
  entity.orderID = event.params.orderID
  entity.maker = event.params.maker

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.poolAddress = event.address

  entity.save()
}

export function handlePlaceSellOrder(event: PlaceSellOrderEvent): void {
  let entity = new PlaceSellOrder(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.orderOption = event.params.orderOption
  entity.orderPrice = event.params.orderPrice
  entity.orderAmount = event.params.orderAmount
  entity.orderID = event.params.orderID
  entity.maker = event.params.maker

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.poolAddress = event.address

  entity.save()
}

export function handlePlatformClaim(event: PlatformClaimEvent): void {
  let entity = new PlatformClaim(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.wallet = event.params.wallet
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.poolAddress = event.address

  entity.save()
}

export function handleResolverClaim(event: ResolverClaimEvent): void {
  let entity = new ResolverClaim(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.wallet = event.params.wallet
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.poolAddress = event.address

  entity.save()
}

export function handleResolverSet(event: ResolverSetEvent): void {
  let entity = new ResolverSet(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.resolver = event.params.resolver

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.poolAddress = event.address

  entity.save()
}

export function handleSync(event: SyncEvent): void {
  let entity = new Sync(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.pair = event.params.pair
  entity.optionVotes = event.params.optionVotes
  entity.allVotes = event.params.allVotes

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.poolAddress = event.address

  entity.save()
}

export function handleOpenDispute(event: OpenDisputeEvent): void {
  let entity = new OpenDispute(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )

  entity.caller = event.params.caller
  entity.currentWinner = event.params.currentWinner
  entity.disputeFee = event.params.disputeFee

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.poolAddress = event.address

  entity.save()
}

export function handleRainTokenBurned(event: RainTokenBurnedEvent): void {
  let entity = new RainTokenBurned(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )

  entity.amountBurned = event.params.amountBurned

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.poolAddress = event.address

  entity.save()
}