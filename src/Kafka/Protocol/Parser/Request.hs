module Kafka.Protocol.Parser.Request
(readRequest,
 readRequestFromFile
) where 

import Kafka.Protocol.Types
import Kafka.Protocol.Parser.Data
import Kafka.Protocol.Serializer
import Data.Binary.Get
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL 

getMessageSets :: Int -> Get [MessageSet]
getMessageSets i = do 
  --empty <- isEmpty 
  if (i < 1)
    then return []
    else do messageSet <- messageSetParser
            messageSets <- getMessageSets $ i - (fromIntegral $ BL.length $ buildMessageSet messageSet)
            -- TODO: better Solution for messageSetLength?
            return (messageSet:messageSets)

partitionParser :: Get RqPrPartition
partitionParser = do 
  partitionNumber <- getWord32be
  messageSetSize <- getWord32be
  messageSet <- getMessageSets $ fromIntegral messageSetSize
  return $ RqPrPartition partitionNumber messageSetSize messageSet

getPartitions :: Int -> Get [RqPrPartition]
getPartitions i = do
  if (i < 1)
    then return []
    else do partition <- partitionParser
            partitions <- getPartitions $ i-1
            return (partition:partitions)

topicParser :: Get RqPrTopic 
topicParser = do 
  topicNameLen <- getWord16be
  topicName <- getByteString $ fromIntegral topicNameLen
  numPartitions <- getWord32be
  partitions <- getPartitions $ fromIntegral numPartitions
  return $ RqPrTopic topicNameLen topicName numPartitions partitions

getTopics :: Int -> Get [RqPrTopic]
getTopics i = do 
  if (i < 1)
    then return []
    else do topic <- topicParser
            topics <- getTopics $ i-1
            return (topic:topics)

produceRequestParser :: Get Request
produceRequestParser = do 
  requiredAcks <- getWord16be
  timeout <- getWord32be 
  numTopics <- getWord32be
  topics <- getTopics $ fromIntegral numTopics
  return $ ProduceRequest requiredAcks timeout numTopics topics

topicNameParser :: Get TopicName
topicNameParser = do 
  topicNameLen <- getWord16be
  topicName <- getByteString $ fromIntegral topicNameLen
  return topicName

getTopicNames :: Int -> Get [TopicName]
getTopicNames i = do
  if (i < 1)
    then return []
    else do topicName <- topicNameParser
            topicNames <- getTopicNames $ i-1
            return (topicName:topicNames)

metadataRequestParser :: Get Request
metadataRequestParser = do 
  numTopicNames <- getWord32be
  topics <- getTopicNames $ fromIntegral numTopicNames
  return $ MetadataRequest topics

--fetchRequestParser :: Get Request
--fetchRequestParser = do
--  replicaId     <- getWord32be
--  maxWaitTime   <- getWord32be
--  minBytes      <- getWord32be
--  topicNameLen  <- getWord16be
--  topicName     <- getByteString $ fromIntegral topicNameLen
--  partition     <- getWord32be
--  fetchOffset   <- getWord64be
--  maxBytes      <- getWord32be
--  return $ FetchRequest replicaId maxWaitTime minBytes

requestMessageParser :: Get RequestMessage 
requestMessageParser = do 
  requestSize <- getWord32be
  apiKey <- getWord16be
  apiVersion <- getWord16be 
  correlationId <- getWord32be 
  clientIdLen <- getWord16be 
  clientId <- getByteString $ fromIntegral clientIdLen
  request <- case (fromIntegral apiKey) of
    0 -> produceRequestParser
--    1 -> fetchRequestParser
    3 -> metadataRequestParser
  --request <- produceRequestParser
  return $ RequestMessage requestSize apiKey apiVersion correlationId clientIdLen clientId request

readRequest :: BL.ByteString -> IO RequestMessage
readRequest a = do 
  return (runGet requestMessageParser a)

readRequestFromFile :: String -> IO RequestMessage --Temp
readRequestFromFile a = do 
  input <- BL.readFile a 
  return (runGet requestMessageParser input)

