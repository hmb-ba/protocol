module Kafka.Protocol.Parser.Response
( produceResponseMessageParser
, fetchResponseMessageParser
, metadataResponseMessageParser
) where 

import Kafka.Protocol.Types
import Kafka.Protocol.Parser.Data
import Kafka.Protocol.Serializer.Data
import Data.Binary.Get
import qualified Data.ByteString.Lazy as BL

parseList :: Int -> (Get a) -> Get [a]
parseList i p = do 
  if (i < 1) 
    then return []
    else do x <- p
            xs <- parseList (i-1) p
            return (x:xs)

rsTopicParser :: (Get RsPayload) -> Get RsTopic 
rsTopicParser p = do 
  topicNameLen <- getWord16be
  topicName <- getByteString $ fromIntegral topicNameLen
  numPayloads <- getWord32be
  payloads <- parseList (fromIntegral numPayloads) p
  return $ RsTopic topicNameLen topicName numPayloads payloads

---------------------
-- Produce Response (Pr)
---------------------
rsPrErrorParser :: Get RsPayload 
rsPrErrorParser= do 
  partitionNumber <- getWord32be
  errorCode <- getWord16be 
  offset <- getWord64be 
  return $! RsPrPayload partitionNumber errorCode offset

produceResponseParser :: Get Response
produceResponseParser = do 
  topic <- rsTopicParser rsPrErrorParser
  return $! ProduceResponse topic

produceResponseMessageParser :: Get ResponseMessage
produceResponseMessageParser = do 
  correlationId <- getWord32be 
  unknown <- getWord32be
  numResponses <- getWord32be
  responses <- parseList (fromIntegral numResponses) produceResponseParser
  return $! ResponseMessage correlationId numResponses responses
---------------------
-- Fetch Response (Ft)
---------------------

-- TODO: Duplicated Code (Serializer.Request)
parseMessageSets :: Int -> Get [MessageSet]
parseMessageSets i = do
    if (i < 1)
    then return []
    else do messageSet <- messageSetParser
            messageSets <- parseMessageSets $ i - (fromIntegral $ BL.length $ buildMessageSet messageSet)
            return (messageSet:messageSets)

fetchResponseMessageParser :: Get ResponseMessage 
fetchResponseMessageParser = do 
  correlationId <- getWord32be 
  unknown <- getWord32be
  numResponses <- getWord32be
  responses <- parseList (fromIntegral numResponses) fetchResponseParser
  return $! ResponseMessage correlationId numResponses responses

fetchResponseParser :: Get Response
fetchResponseParser = do 
  topicNameLen <- getWord16be
  topicsName <- getByteString $ fromIntegral topicNameLen
  numPayloads <- getWord32be
  payloads <- parseList (fromIntegral numPayloads) rsFtPayloadParser
  return $! FetchResponse topicNameLen topicsName numPayloads payloads

rsFtPayloadParser :: Get RsPayload 
rsFtPayloadParser = do 
  partition <- getWord32be
  errorCode <- getWord16be
  hwMarkOffset <- getWord64be
  messageSetSize <- getWord32be
  messageSet <- parseMessageSets (fromIntegral messageSetSize)
  return $! RsFtPayload partition errorCode hwMarkOffset messageSetSize messageSet

---------------------
-- Metdata Response (Md)
---------------------
rsMdPartitionMdParser :: Get RsMdPartitionMetadata
rsMdPartitionMdParser = do 
  errorcode <- getWord16be
  partition <- getWord32be
  leader <- getWord32be
  numreplicas <- getWord32be
  replicas <- parseList (fromIntegral numreplicas) getWord32be 
  numIsr <- getWord32be
  isrs <- parseList (fromIntegral numIsr) getWord32be
  return $! RsMdPartitionMetadata errorcode partition leader numreplicas replicas numIsr isrs

rsMdPayloadTopicParser :: Get RsPayload
rsMdPayloadTopicParser = do 
  errorcode <- getWord16be 
  topicNameLen <- getWord16be
  topicName <- getByteString $ fromIntegral topicNameLen 
  numPartition <- getWord32be 
  partitions <- parseList (fromIntegral numPartition) rsMdPartitionMdParser
  return $! RsMdPayloadTopic errorcode topicNameLen topicName numPartition partitions 

rsMdPayloadBrokerParser :: Get RsPayload 
rsMdPayloadBrokerParser = do 
  node <- getWord32be 
  hostLen <- getWord16be
  host <- getByteString $ fromIntegral hostLen
  port <- getWord32be 
  return $! RsMdPayloadBroker node hostLen host port

metadataResponseParser :: Get Response 
metadataResponseParser = do 
  numBrokers <- getWord32be
  brokers <- parseList (fromIntegral numBrokers) rsMdPayloadBrokerParser
  numTopics   <- getWord32be
  topics <- parseList (fromIntegral numTopics) rsMdPayloadTopicParser
  return $! MetadataResponse numBrokers brokers numTopics topics 

metadataResponseMessageParser :: Get ResponseMessage 
metadataResponseMessageParser = do 
  correlationId <- getWord32be 
  unknown <- getWord32be
  numResponses <- getWord32be
  responses <- parseList (fromIntegral numResponses) metadataResponseParser
  return $! ResponseMessage correlationId numResponses responses

