import {
  ExternalSourceLaunched as ExternalSourceLaunchedEvent,
  RefundClaimed as RefundClaimedEvent,
  RewardClaimed as RewardClaimedEvent,
  TimeExtended as TimeExtendedEvent,
  VoteCasted as VoteCastedEvent,
  WinnerCalculated as WinnerCalculatedEvent,
} from "../generated/templates/ExternalSource/ExternalSource"
import {
  ExternalSourceLaunched,
  RefundClaimed,
  RewardClaimed,
  TimeExtended,
  VoteCasted,
  WinnerCalculated,
} from "../generated/schema"

export function handleExternalSourceLaunched(
  event: ExternalSourceLaunchedEvent,
): void {
  let entity = new ExternalSourceLaunched(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.externalSourceInstance_noOfOracles =
    event.params.externalSourceInstance.noOfOracles
  entity.externalSourceInstance_rewardPerOracle =
    event.params.externalSourceInstance.rewardPerOracle
  entity.externalSourceInstance_loyaltyFee =
    event.params.externalSourceInstance.loyaltyFee
  entity.externalSourceInstance_totalExternalSourceCost =
    event.params.externalSourceInstance.totalExternalSourceCost
  entity.externalSourceInstance_totalOracleReward =
    event.params.externalSourceInstance.totalOracleReward
  entity.externalSourceInstance_startTime =
    event.params.externalSourceInstance.startTime
  entity.externalSourceInstance_endTime =
    event.params.externalSourceInstance.endTime
  entity.externalSourceInstance_numberOfOptions =
    event.params.externalSourceInstance.numberOfOptions
  entity.externalSourceInstance_externalSourceURI =
    event.params.externalSourceInstance.externalSourceURI
  entity.externalSourceInstance_creator =
    event.params.externalSourceInstance.creator

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.oracleAddress = event.address

  entity.save()
}

export function handleRefundClaimed(event: RefundClaimedEvent): void {
  let entity = new RefundClaimed(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.contractAddress = event.params.contractAddress
  entity.claimer = event.params.claimer
  entity.refundAmount = event.params.refundAmount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.oracleAddress = event.address

  entity.save()
}

export function handleRewardClaimed(event: RewardClaimedEvent): void {
  let entity = new RewardClaimed(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.claimer = event.params.claimer
  entity.reward = event.params.reward

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.oracleAddress = event.address

  entity.save()
}

export function handleTimeExtended(event: TimeExtendedEvent): void {
  let entity = new TimeExtended(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.contractAddress = event.params.contractAddress
  entity.oldEndTime = event.params.oldEndTime
  entity.newEndTime = event.params.newEndTime

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.oracleAddress = event.address

  entity.save()
}

export function handleVoteCasted(event: VoteCastedEvent): void {
  let entity = new VoteCasted(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.voter = event.params.voter
  entity.option = event.params.option

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.oracleAddress = event.address

  entity.save()
}

export function handleWinnerCalculated(event: WinnerCalculatedEvent): void {
  let entity = new WinnerCalculated(
    event.transaction.hash.concatI32(event.logIndex.toI32()),
  )
  entity.caller = event.params.caller
  entity.option = event.params.option

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.oracleAddress = event.address

  entity.save()
}
