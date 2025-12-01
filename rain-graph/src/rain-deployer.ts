import {
  PoolCreated as PoolCreatedEvent,
} from "../generated/RainDeployer/RainDeployer"
import {
  PoolCreated,
} from "../generated/schema"
import { RainPool } from '../generated/templates'

export function handlePoolCreated(event: PoolCreatedEvent): void {
  let entity = new PoolCreated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.poolAddress = event.params.poolAddress
  entity.poolCreator = event.params.poolCreator
  entity.uri = (event.params.uri).toString().length > 0 ? (event.params.uri).toString() : ""

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
  RainPool.create(event.params.poolAddress);
}
