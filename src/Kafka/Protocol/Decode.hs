{- |
Module      :  Kafka.Protocol.Decode
Description :  Decode from Apache Kafka Protocol binary format
Copyright   :  (c) Marc Juchli, Lorenz Wolf
License     :
Maintainer  :  mail@marcjuch.li, lorenz.wolf@bluewin.ch
Stability   :  experimental
Portability :  portable

This module exposes functions for decoding requests and responses of kafka
prototol implemention.

-}
module Kafka.Protocol.Decode
    ( messageSetParser
    , requestMessageParser
    , produceResponseMessageParser
    , fetchResponseMessageParser
    , metadataResponseMessageParser
    ) where

import Kafka.Protocol.Types
import Data.Binary.Get
import Data.Binary.Put
import qualified Data.ByteString.Lazy as BL
import Kafka.Protocol.Encode
import qualified Data.ByteString as BS


-------------------------------------------------------------------------------
-- Common
-------------------------------------------------------------------------------

-- | Generic and recursive parsing to create a list. First argument is the
-- length of the list that is to be created.
parseList :: Int -> (Get a) -> Get [a]
parseList i p = do
  if (i < 1)
    then return []
    else do x <- p
            xs <- parseList (i-1) p
            return (x:xs)
  -- FIXME (SM): Use the standard libraries. 'parseList' is just an instance
  -- of 'replicateM'.

-- | MessageSets are not preceded by an int32 like other array elements in the
-- protocol. The first argument represents the lenght of the total sequence.
parseMessageSets :: Int -> Get [MessageSet]
parseMessageSets i = do
    if (i < 1)
    then return []
    else do messageSet <- messageSetParser
            -- FIXME (SM): This seems to be highly inefficient. For each
            -- messageSet you have to build the previous one to get its
            -- length. You should just return that length in the
            -- 'messageSetParser' together with the parsed message set.
            messageSets <- parseMessageSets $
                              i - (fromIntegral $
                                    BL.length $
                                    runPut $
                                    buildMessageSet messageSet
                                  )
            return (messageSet:messageSets)


-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------

payloadParser :: Get Payload
payloadParser = do
  -- FIXME (SM): what style of alignment are you using here?
  magic       <- getWord8
  attr        <- getWord8
  key      <- getWord32be
  paylen      <- getWord32be
  payload     <- getByteString $ fromIntegral paylen
  -- FIXME (SM): use explicit record field assignments to make this code
  -- robust. It is too easy to hide a stupid mistake in the positional
  -- assignments that all have the same type.
  return $! Payload magic attr key paylen payload

messageParser :: Get Message
messageParser = do
  crc         <- getWord32be
  p           <- payloadParser
  return $! Message crc p

messageSetParser :: Get MessageSet
messageSetParser = do
  offset      <- getWord64be
  len         <- getWord32be
  message     <- messageParser
  return $! MessageSet offset len message


-------------------------------------------------------------------------------
-- Request
-------------------------------------------------------------------------------

topicNameParser :: Get RqTopicName
topicNameParser = do
  topicNameLen  <- getWord16be
  topicName     <- getByteString $ fromIntegral topicNameLen
  return $ RqTopicName topicNameLen topicName


topicParser :: (Get Partition) -> Get RqTopic
topicParser p = do
  topicNameLen  <- getWord16be
  topicName     <- getByteString $ fromIntegral topicNameLen
  numPartitions <- getWord32be
  partitions    <- parseList (fromIntegral numPartitions) p
  return $ RqTopic topicNameLen topicName numPartitions partitions

-- | Produce Request (Pr)
rqPrPartitionParser = do
  partitionNumber <- getWord32be
  messageSetSize <- getWord32be
  messageSets   <- parseMessageSets (fromIntegral messageSetSize)
  return $ RqPrPartition partitionNumber messageSetSize messageSets

produceRequestParser :: Get Request
produceRequestParser = do
  requiredAcks  <- getWord16be
  timeout       <- getWord32be
  numTopics     <- getWord32be
  topics        <- parseList (fromIntegral numTopics) (topicParser rqPrPartitionParser)
  return $ ProduceRequest requiredAcks timeout numTopics topics

-- | Fetch Request (Ft)
rqFtPartitionParser :: Get Partition
rqFtPartitionParser = do
  partitionNumber <- getWord32be
  fetchOffset   <- getWord64be
  maxBytes      <- getWord32be
  return $ RqFtPartition partitionNumber fetchOffset maxBytes

fetchRequestParser :: Get Request
fetchRequestParser = do
  replicaId     <- getWord32be
  maxWaitTime   <- getWord32be
  minBytes      <- getWord32be
  numTopics     <- getWord32be
  topics        <- parseList (fromIntegral numTopics) (topicParser rqFtPartitionParser)
  return $ FetchRequest replicaId maxWaitTime minBytes numTopics topics

-- | Metadata Request (Md)
metadataRequestParser :: Get Request
metadataRequestParser = do
  numTopics     <- getWord32be
  topicNames    <- parseList (fromIntegral numTopics) topicNameParser
  return $ MetadataRequest numTopics topicNames

-- | Offset Request (Of)
offsetRequestParser :: Get Request
offsetRequestParser = do
  replicaId     <- getWord32be
  numTopics     <- getWord32be
  topics        <- parseList (fromIntegral numTopics) (topicParser rqOfPartitionParser)
  return $ OffsetRequest replicaId numTopics topics

rqOfPartitionParser :: Get Partition
rqOfPartitionParser = do
  partition     <- getWord32be
  time          <- getWord64be
  maxNumOfOf    <- getWord32be
  return $ RqOfPartition partition time maxNumOfOf

-- | Request Message Header (Rq)
requestMessageParser :: Get RequestMessage
requestMessageParser = do
  rqSize        <- getWord32be
  apiKey        <- getWord16be
  apiVersion    <- getWord16be
  correlationId <- getWord32be
  clientIdLen   <- getWord16be
  clientId      <- getByteString $ fromIntegral clientIdLen
  -- FIXME (SM): why do you use from integral here? You can pattern-match as
  -- well on the Word16
  request       <- case (fromIntegral apiKey) of
    0 -> produceRequestParser
    1 -> fetchRequestParser
    3 -> metadataRequestParser
    -- FIXME (SM): the missing default-case will make this function fail hard
    -- instead of resutling in a parse failure with an informative error
    -- message.
  return $ RequestMessage rqSize apiKey apiVersion correlationId clientIdLen clientId request



-------------------------------------------------------------------------------
-- Response
-------------------------------------------------------------------------------

rsTopicParser :: (Get RsPayload) -> Get RsTopic
rsTopicParser p = do
  topicNameLen  <- getWord16be
  topicName     <- getByteString $ fromIntegral topicNameLen
  numPayloads   <- getWord32be
  payloads      <- parseList (fromIntegral numPayloads) p
  return $ RsTopic topicNameLen topicName numPayloads payloads

-- | Produce Response (Pr)
rsPrErrorParser :: Get RsPayload
rsPrErrorParser= do
  partitionNumber <- getWord32be
  errorCode     <- getWord16be
  offset        <- getWord64be
  return $! RsPrPayload partitionNumber errorCode offset

produceResponseParser :: Get Response
produceResponseParser = do
  len           <- getWord32be
  topics        <- parseList (fromIntegral len) $ rsTopicParser rsPrErrorParser
  return $! ProduceResponse len topics

produceResponseMessageParser :: Get ResponseMessage
produceResponseMessageParser = do
  size          <- getWord32be
  correlationId <- getWord32be
  response      <- produceResponseParser
  return $! ResponseMessage size correlationId response

-- | Fetch Response (Ft)
fetchResponseMessageParser :: Get ResponseMessage
fetchResponseMessageParser = do
  size          <- getWord32be
  correlationId <- getWord32be
  response      <- fetchResponseParser
  return $! ResponseMessage size correlationId response

fetchResponseParser :: Get Response
fetchResponseParser = do
  len           <- getWord32be
  topics        <- parseList (fromIntegral len) $ rsTopicParser rsFtPayloadParser
  return $! FetchResponse len topics

rsFtPayloadParser :: Get RsPayload
rsFtPayloadParser = do
  partition     <- getWord32be
  errorCode     <- getWord16be
  hwMarkOffset  <- getWord64be
  messageSetSize <- getWord32be
  messageSet    <- parseMessageSets (fromIntegral messageSetSize)
  return $! RsFtPayload partition errorCode hwMarkOffset messageSetSize messageSet

-- | Metdata Response (Md)
rsMdPartitionMdParser :: Get RsMdPartitionMetadata
rsMdPartitionMdParser = do
  errorcode     <- getWord16be
  partition     <- getWord32be
  leader        <- getWord32be
  numreplicas   <- getWord32be
  replicas      <- parseList (fromIntegral numreplicas) getWord32be
  numIsr        <- getWord32be
  isrs          <- parseList (fromIntegral numIsr) getWord32be
  return $! RsMdPartitionMetadata errorcode partition leader numreplicas replicas numIsr isrs

rsMdPayloadTopicParser :: Get RsPayload
rsMdPayloadTopicParser = do
  errorcode     <- getWord16be
  topicNameLen  <- getWord16be
  topicName     <- getByteString $ fromIntegral topicNameLen
  numPartition  <- getWord32be
  partitions    <- parseList (fromIntegral numPartition) rsMdPartitionMdParser
  return $! RsMdPayloadTopic errorcode topicNameLen topicName numPartition partitions

rsMdPayloadBrokerParser :: Get RsPayload
rsMdPayloadBrokerParser = do
  node          <- getWord32be
  hostLen       <- getWord16be
  host          <- getByteString $ fromIntegral hostLen
  port          <- getWord32be
  return $! RsMdPayloadBroker node hostLen host port

metadataResponseParser :: Get Response
metadataResponseParser = do
  numBrokers    <- getWord32be
  brokers       <- parseList (fromIntegral numBrokers) rsMdPayloadBrokerParser
  numTopics     <- getWord32be
  topics        <- parseList (fromIntegral numTopics) rsMdPayloadTopicParser
  return $! MetadataResponse numBrokers brokers numTopics topics

metadataResponseMessageParser :: Get ResponseMessage
metadataResponseMessageParser = do
  size          <- getWord32be
  correlationId <- getWord32be
  response      <- metadataResponseParser
  return $! ResponseMessage size correlationId response

