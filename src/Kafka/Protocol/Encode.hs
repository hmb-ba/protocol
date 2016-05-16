{- |
Module      :  Kafka.Protocol.Encode
Description :  Encode to Apache Kafka Protocol compatible binary format
Copyright   :  (c) Marc Juchli, Lorenz Wolf
License     :
Maintainer  :  mail@marcjuch.li, lorenz.wolf@bluewin.ch
Stability   :  experimental
Portability :  portable

This module exposes Encode functionalities for kafka protocol implementation.
-}
module Kafka.Protocol.Encode
    () where

import           Data.Binary
import           Data.Binary.Put
import           Data.Binary.Get
import qualified Data.ByteString.Lazy           as BL
import           Data.Digest.CRC32
import           Kafka.Protocol.Types
import qualified Network.Socket.ByteString.Lazy as SBL


-------------------------------------------------------------------------------
-- | Data
-------------------------------------------------------------------------------

instance Binary MessageSet where
  put e = do
    putWord64be $ msOffset e
    putWord32be $ msLen e
    put         $ msMessage e

  get = do
    offset  <- getWord64be
    len     <- getWord32be
    message <- get :: Get Message
    return $! MessageSet { msOffset = offset, msLen = len, msMessage = message }

instance Binary Message where
  put e = do
    putWord32be $ mgCrc e
    put         $ mgPayload e

  get = do
    crc <- getWord32be
    p   <- get :: Get Payload
    return $! Message { mgCrc = crc, mgPayload = p }

instance Binary Payload where
  put e = do
    putWord8      $      plMagic e
    putWord8      $      plAttr e
    putWord32be   $      plKey e
    putWord32be   $      plValueLen e
    putByteString $    plValue e

  get = do
    magic   <- getWord8
    attr    <- getWord8
    key     <- getWord32be
    paylen  <- getWord32be
    payload <- getByteString $ fromIntegral paylen
    return $! Payload { plMagic    = magic
                      , plAttr     = attr
                      , plKey      = key
                      , plValueLen = paylen
                      , plValue    = payload }


-------------------------------------------------------------------------------
-- | Request
-------------------------------------------------------------------------------

instance Binary RequestMessage where
  put e = do
    putWord32be   $ rqSize e
    putWord16be   $ rqApiKey e
    putWord16be   $ rqApiVersion e
    putWord32be   $ rqCorrelationId e
    putWord16be   $ rqClientIdLen e
    putByteString $ rqClientId e
    put           $ rqRequest e

  get = do
    size   <- getWord32be
    apiK   <- getWord16be
    apiV   <- getWord16be
    corrId <- getWord32be
    cIdLen <- getWord16be
    cId    <- getByteString $ fromIntegral cIdLen
    rq     <- case apiK of
      -- TODO: I truely wanna use Binary type class definitions in the way
      -- such that return type overloading is being used as follows:
      -- 1 -> get :: Get FetchRequest
      -- 2- > get :: Get MetadataRequest
      -- ...
      0 -> produceRequestParser
      1 -> fetchRequestParser
      3 -> metadataRequestParser
      -- FIXME (SM): the missing default-case will make this function fail hard
      -- instead of resutling in a parse failure with an informative error
      -- message.
    return RequestMessage { rqSize          = size
                          , rqApiKey        = apiK
                          , rqApiVersion    = apiV
                          , rqCorrelationId = corrId
                          , rqClientIdLen   = cIdLen
                          , rqClientId      = cId
                          , rqRequest       = rq }


instance Binary RqTopic where
  put t = do
    putWord16be $      rqToNameLen t
    putByteString $    rqToName t
    putWord32be $      rqToNumPartitions t
    mapM_ put $ rqToPartitions t

  get = undefined


instance Binary RqTopicName where
  put e = do
    putWord16be $      rqTnNameLen e
    putByteString $    rqTnName e

  get = do
    topicNameLen  <- getWord16be
    topicName     <- getByteString $ fromIntegral topicNameLen
    return $ RqTopicName topicNameLen topicName


instance Binary Partition where
  put e@RqPrPartition{} = do
    putWord32be $      rqPrPartitionNumber e
    putWord32be $      rqPrMessageSetSize e
    mapM_ put $ rqPrMessageSet e
  put p@RqFtPartition{} = do
    putWord32be $      rqFtPartitionNumber p
    putWord64be $      rqFtFetchOffset p
    putWord32be $      rqFtMaxBytes p
  put e@RqOfPartition{} = do
    putWord32be $      rqOfPartitionNumber e
    putWord64be $      rqOfTime e
    putWord32be $      rqOfMaxNumOffset e

  get = undefined


instance Binary Request where
  put e@ProduceRequest{} = do
    putWord16be $      rqPrRequiredAcks e
    putWord32be $      rqPrTimeout e
    putWord32be $      rqPrNumTopics e
    mapM_ put $ rqPrTopics e
  put e@FetchRequest{} = do
    putWord32be $      rqFtReplicaId e
    putWord32be $      rqFtMaxWaitTime e
    putWord32be $      rqFtMinBytes e
    putWord32be $      rqFtNumTopics e
    mapM_ put $ rqPrTopics e
  put e@MetadataRequest{} = do
    putWord32be $      rqMdNumTopics e
    mapM_ put $ rqPrTopics e
  put e@OffsetRequest{} = do
    putWord32be $      rqOfReplicaId e
    putWord32be $      rqOfNumTopics e
    mapM_ put $ rqPrTopics e

  get = undefined

-------------------------------------------------------------------------------
-- Response
-------------------------------------------------------------------------------

instance Binary ResponseMessage where
  put rm = do
    putWord32be $      rsSize rm
    putWord32be $      rsCorrelationId rm
    mapM_ put $ rsResponses rm

  get = undefined

instance Binary RsTopic where
  put t = do
    putWord16be $      rsTopicNameLen t
    putByteString $    rsTopicName t
    putWord32be $      rsNumPayloads t
    mapM_ put $ rsPayloads t

  get = undefined

instance Binary RsPayload where
  put e@RsPrPayload{} = do
    putWord32be $      rsPrPartitionNumber e
    putWord16be $      rsPrCode e
    putWord64be $      rsPrOffset e

  put p@RsFtPayload{} = do
    putWord32be $      rsFtPartitionNumber p
    putWord16be $      rsFtErrorCode p
    putWord64be $      rsFtHwMarkOffset p
    putWord32be $      rsFtMessageSetSize p
    mapM_ put $ rsFtMessageSets p

  put t@RsMdPayloadTopic{} = do
    putWord16be $      rsMdTopicErrorCode t
    putWord16be $      rsMdTopicNameLen t
    putLazyByteString $ BL.fromStrict $ rsMdTopicName t
    putWord32be $      rsMdNumPartitionMd t
    mapM_ put $ rsMdPartitionMd t

  put p@RsMdPayloadBroker{} = do
    putWord32be $      rsMdNodeId p
    putWord16be $      rsMdHostLen p
    putLazyByteString $ BL.fromStrict(rsMdHost p)
    putWord32be $      rsMdPort p

  put p@RsOfPayload{} = do
    putWord32be $      rsOfPartitionNumber p
    putWord64be $      rsOfErrorCode p
    putWord32be $      rsOfNumOffsets p
    mapM_ putWord64be $ rsOfOffsets p



  get = undefined



instance Binary Response where
  put rs@ProduceResponse{} = do
    putWord32be $      rsPrNumTopic rs
    mapM_ put $ rsPrTopic rs
  put rs@FetchResponse{} = do
    putWord32be   $ rsFtNumTopic rs
    mapM_ put $ rsFtTopic rs
  put rs@OffsetResponse{} = do
    putWord32be $      rsOfNumTopic rs
    mapM_ put $ rsFtTopic rs
  put rs@MetadataResponse{} = do
    putWord32be $      rsMdNumBroker rs
    mapM_ put $ rsMdBrokers rs
    putWord32be $      rsMdNumTopicMd rs
    mapM_ put $ rsMdTopicMetadata rs

  get = undefined


-- | Metadata Response (Md)
instance Binary RsMdPartitionMetadata where
  put p = do
    putWord16be $      rsMdPartitionErrorCode p
    putWord32be $      rsMdPartitionId p
    putWord32be $      rsMdLeader p
    putWord32be $      rsMdNumReplicas p
    mapM_ putWord32be $ rsMdReplicas p
    putWord32be  $     rsMdNumIsrs p
    mapM_ putWord32be $ rsMdIsrs p

  get = undefined
