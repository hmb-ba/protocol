module Kafka.Protocol.Parser.Request
( requestMessageParser
) where 

import Kafka.Protocol.Types
import Kafka.Protocol.Parser.Data
import Kafka.Protocol.Serializer
import Data.Binary.Get
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL 


parseList :: Int -> (Get a)-> Get [a]
parseList i p = do
  if (i < 1)
    then return []
    else do x <- p
            xs <- parseList (i-1) p
            return (x:xs)


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

------------------------
-- Produce Request (Pr)
------------------------
parseMessageSets :: Int -> Get [MessageSet]
parseMessageSets i = do
    if (i < 1)
    then return []
    else do messageSet <- messageSetParser
            messageSets <- parseMessageSets $ i - (fromIntegral $ BL.length $ buildMessageSet messageSet)
            return (messageSet:messageSets)

rqPrPartitionParser = do 
  partitionNumber   <- getWord32be
  messageSetSize    <- getWord32be
  messageSets       <- parseMessageSets (fromIntegral messageSetSize)
  return $ RqPrPartition partitionNumber messageSetSize messageSets

produceRequestParser :: Get Request
produceRequestParser = do 
  requiredAcks  <- getWord16be
  timeout       <- getWord32be 
  numTopics     <- getWord32be
  topics        <- parseList (fromIntegral numTopics) (topicParser rqPrPartitionParser)
  return $ ProduceRequest requiredAcks timeout numTopics topics

---------------------
-- Fetch Request (Ft)
---------------------

rqFtPartitionParser :: Get Partition
rqFtPartitionParser = do
  partitionNumber <- getWord32be
  fetchOffset     <- getWord64be
  maxBytes        <- getWord32be
  return $ RqFtPartition partitionNumber fetchOffset maxBytes

fetchRequestParser :: Get Request
fetchRequestParser = do
  replicaId     <- getWord32be
  maxWaitTime   <- getWord32be
  minBytes      <- getWord32be
  numTopics     <- getWord32be
  topics        <- parseList (fromIntegral numTopics) (topicParser rqFtPartitionParser)
  return $ FetchRequest replicaId maxWaitTime minBytes numTopics topics

------------------------
-- Metadata Request (Md)
------------------------
metadataRequestParser :: Get Request
metadataRequestParser = do 
  numTopics     <- getWord32be 
  topicNames    <- parseList (fromIntegral numTopics) topicNameParser
  return $ MetadataRequest numTopics topicNames

------------------------
-- Offset Request (Of)
------------------------
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
------------------------
-- Request Message Header (Rq)
------------------------

requestMessageParser :: Get RequestMessage 
requestMessageParser = do 
  requestSize   <- getWord32be
  apiKey        <- getWord16be
  apiVersion    <- getWord16be 
  correlationId <- getWord32be 
  clientIdLen   <- getWord16be 
  clientId      <- getByteString $ fromIntegral clientIdLen
  request       <- case (fromIntegral apiKey) of
    0 -> produceRequestParser
    1 -> fetchRequestParser
    3 -> metadataRequestParser
  --request <- produceRequestParser
  return $ RequestMessage requestSize apiKey apiVersion correlationId clientIdLen clientId request

