{- |
Module      :  Kafka.Protocol.Encode
Description :  Encode to Apache Kafka Protocol compatible binary format
Copyright   :  (c) Marc Juchli, Lorenz Wolf
License     :
Maintainer  :  mail@marcjuch.li, lorenz.wolf@bluewin.ch
Stability   :  experimental
Portability :  portable
-}
module Kafka.Protocol.Encode
    ( buildMessageSet
    , buildMessage
    , buildPayload

    , buildRqMessage
    , buildMessageSets
    , buildProduceRequest
    , buildFetchRequest
    , buildMetadataRequest

    , buildPrResponseMessage
    , buildFtRsMessage
    , buildMdRsMessage
    ) where

import qualified Data.ByteString.Lazy as BL
import Data.Binary.Put
import Kafka.Protocol.Types
import Data.Digest.CRC32
import qualified Network.Socket.ByteString.Lazy as SBL

-------------------------------------------------------------------------------
-- | Common
-------------------------------------------------------------------------------

-- | Generic list building that takes a builder function and a list
buildList :: (a -> Put) -> [a] -> Put
buildList builder [] = putLazyByteString BL.empty
buildList builder [x] = builder x
buildList builder (x:xs) = do
  builder x
  buildList builder xs


-------------------------------------------------------------------------------
-- | Data
-------------------------------------------------------------------------------

buildMessageSets :: [MessageSet] -> Put
buildMessageSets [] = putLazyByteString BL.empty
buildMessageSets [x] = buildMessageSet x
buildMessageSets (x:xs) = do
  buildMessageSet x
  buildMessageSets xs

buildMessageSet :: MessageSet -> Put
buildMessageSet e = do
  putWord64be $ offset e
  putWord32be $ len e
  buildMessage $ message e

buildMessage :: Message -> Put
buildMessage e = do
  putWord32be $ crc e
  buildPayload $ payload e

buildPayload :: Payload -> Put
buildPayload e = do
  putWord8    $ magic e
  putWord8    $ attr e
  putWord32be $ keylen $ e
  putWord32be $ payloadLen $ e
  putByteString $ payloadData $ e


-------------------------------------------------------------------------------
-- | Request
-------------------------------------------------------------------------------

buildRqMessage :: RequestMessage -> Put
buildRqMessage e = do
  putWord32be $ rqSize e
  putWord16be $ rqApiKey e
  putWord16be $ rqApiVersion e
  putWord32be $ rqCorrelationId e
  putWord16be $ rqClientIdLen e
  putByteString $ rqClientId e
  case (fromIntegral $ rqApiKey e) of
    0 -> buildProduceRequest  $ rqRequest e
    1 -> buildFetchRequest    $ rqRequest e
    3 -> buildMetadataRequest $ rqRequest e
    -- further API Codes not implemented yet

buildTopic :: (Partition -> Put) -> RqTopic -> Put
buildTopic pb t = do
  putWord16be         $ rqTopicNameLen t
  putByteString       $ rqTopicName t
  putWord32be       $ numPartitions t
  buildList pb $ partitions t

buildRqTopicName :: RqTopicName -> Put
buildRqTopicName e = do
  putWord16be         $ topicNameLen e
  putByteString       $ topicName e

-- | Produce Request
buildRqPrPartition :: Partition -> Put
buildRqPrPartition e = do
  putWord32be $ rqPrPartitionNumber e
  putWord32be $ rqPrMessageSetSize e
  buildMessageSets $ rqPrMessageSet e

buildProduceRequest :: Request -> Put
buildProduceRequest e = do
  putWord16be $ rqPrRequiredAcks e
  putWord32be $ rqPrTimeout e
  putWord32be $ rqPrNumTopics e
  buildList (buildTopic buildRqPrPartition) $ rqPrTopics e

-- | Fetch Request
buildRqFtPartition :: Partition -> Put
buildRqFtPartition p = do
  putWord32be $ rqFtPartitionNumber p
  putWord64be $ rqFtFetchOffset p
  putWord32be $ rqFtMaxBytes p

buildFetchRequest :: Request -> Put
buildFetchRequest e = do
  putWord32be $ rqFtReplicaId e
  putWord32be $ rqFtMaxWaitTime e
  putWord32be $ rqFtMinBytes e
  putWord32be $ rqFtNumTopics e
  buildList (buildTopic buildRqFtPartition) $ rqFtTopics e

-- | Metadata Request
buildMetadataRequest :: Request -> Put
buildMetadataRequest e = do
  putWord32be $ rqMdNumTopics e
  buildList buildRqTopicName $ rqMdTopicNames e

-- | Offset Request
buildRqOfPartition :: Partition -> Put
buildRqOfPartition e = do
  putWord32be     $ rqOfPartitionNumber e
  putWord64be     $ rqOfTime e
  putWord32be     $ rqOfMaxNumOffset e

buildOffsetRequest :: Request -> Put
buildOffsetRequest e = do
  putWord32be     $ rqOfReplicaId e
  putWord32be     $ rqOfNumTopics e
  buildList (buildTopic buildRqOfPartition) $ rqOfTopics e


-------------------------------------------------------------------------------
-- Response
-------------------------------------------------------------------------------

buildRsMessage :: (Response -> Put) -> ResponseMessage -> Put
buildRsMessage rsBuilder rm = do
  putWord32be       $ rsCorrelationId rm
  putWord32be       $ fromIntegral 0  -- | Unkown Word32 from original kafka response
  putWord32be       $ rsNumResponses rm
  buildList rsBuilder $ rsResponses rm

buildRsTopic :: (RsPayload -> Put) -> RsTopic -> Put
buildRsTopic b t = do
  putWord16be $ rsTopicNameLen t
  putByteString $ rsTopicName t
  putWord32be $ rsNumPayloads t
  buildList buildRsPrPayload $ rsPayloads t

-- | Produce Response (Pr)
buildRsPrPayload :: RsPayload -> Put
buildRsPrPayload e = do
  putWord32be $ rsPrPartitionNumber e
  putWord16be $ rsPrCode e
  putWord64be $ rsPrOffset e

buildProduceResponse :: Response -> Put
buildProduceResponse e = do
  buildRsTopic buildRsPrPayload $ rsPrTopic e

buildPrResponseMessage :: ResponseMessage -> Put
buildPrResponseMessage rm = buildRsMessage buildProduceResponse rm

-- | Fetch Response (Ft)
buildFtPayload :: RsPayload -> Put
buildFtPayload p =do
  putWord32be       $ rsFtPartitionNumber p
  putWord16be       $ rsFtErrorCode p
  putWord64be       $ rsFtHwMarkOffset p
  putWord32be       $ rsFtMessageSetSize p
  buildMessageSets $ rsFtMessageSets p

buildFtRs :: Response -> Put
buildFtRs rs = do
  putWord16be       $ rsFtTopicNameLen rs
  putLazyByteString $ BL.fromStrict(rsFtTopicName rs)
  putWord32be       $ rsFtNumsPayloads rs
  buildList buildFtPayload $ rsFtPayloads rs

buildFtRsMessage :: ResponseMessage -> Put
buildFtRsMessage rm = buildRsMessage buildFtRs rm

-- | Offset Response (Of)
buildRsOfPartitionOf :: RsOfPartitionOf -> Put
buildRsOfPartitionOf p = do
  putWord32be     $ rsOfPartitionNumber p
  putWord64be     $ rsOfErrorCode p
  putWord32be     $ rsOfNumOffsets p
  buildList (putWord64be) $ rsOfOffsets p

buildOfRs :: Response -> Put
buildOfRs rs = do
  putWord16be       $ rsOfTopicNameLen rs
  putLazyByteString $ BL.fromStrict(rsOfTopicName rs)
  putWord32be       $ rsOfNumPartitionOfs rs
  buildList buildRsOfPartitionOf $ rsOfPartitionOfs rs

buildOfRsMessage :: ResponseMessage -> Put
buildOfRsMessage rm = buildRsMessage buildOfRs rm

-- | Metadata Response (Md)
buildRsMdPartitionMetadata :: RsMdPartitionMetadata -> Put
buildRsMdPartitionMetadata p = do
  putWord16be   $ rsMdPartitionErrorCode p
  putWord32be   $ rsMdPartitionId p
  putWord32be   $ rsMdLeader p
  putWord32be   $ rsMdNumReplicas p
  buildList (putWord32be) $ rsMdReplicas p
  putWord32be  $ rsMdNumIsrs p
  buildList (putWord32be) $ rsMdIsrs p

buildRsMdPayloadTopic :: RsPayload -> Put
buildRsMdPayloadTopic t = do
  putWord16be   $ rsMdTopicErrorCode t
  putWord16be   $ rsMdTopicNameLen t
  putLazyByteString $ BL.fromStrict $ rsMdTopicName t
  putWord32be   $ rsMdNumPartitionMd t
  buildList buildRsMdPartitionMetadata $ rsMdPartitionMd t

buildRsMdPayloadBroker :: RsPayload -> Put
buildRsMdPayloadBroker p = do
  putWord32be    $ rsMdNodeId p
  putWord16be    $ rsMdHostLen p
  putLazyByteString $ BL.fromStrict(rsMdHost p)
  putWord32be   $ rsMdPort p

buildMdRs :: Response -> Put
buildMdRs rs = do
  putWord32be     $  rsMdNumBroker rs
  buildList buildRsMdPayloadBroker $ rsMdBrokers rs
  putWord32be     $ rsMdNumTopicMd rs
  buildList buildRsMdPayloadTopic $ rsMdTopicMetadata rs

buildMdRsMessage :: ResponseMessage -> Put
buildMdRsMessage rm = buildRsMessage buildMdRs rm


