module Kafka.Protocol.Serializer.Request 
( buildMessageSets
  , buildPartition
  , buildPartitions
  , buildTopic
  , buildTopics
  , buildProduceRequestMessage
  , buildRequestMessage
) where 

import Data.Binary.Put
import qualified Data.ByteString.Lazy as BL
import qualified Network.Socket.ByteString.Lazy as SBL
import Kafka.Protocol.Types
import Kafka.Protocol.Serializer.Data

buildMessageSets :: [MessageSet] -> BL.ByteString
buildMessageSets [] = BL.empty
buildMessageSets (x:xs) = BL.append (buildMessageSet x) (buildMessageSets xs)

buildPartition :: Partition -> BL.ByteString
buildPartition e = runPut $ do 
  putWord32be $ partitionNumber e
  putWord32be $ messageSetSize e
  putLazyByteString $ buildMessageSets $  messageSet e

buildPartitions :: [Partition] -> BL.ByteString
buildPartitions [] = BL.empty
buildPartitions (x:xs) = BL.append (buildPartition x) (buildPartitions xs) 

buildTopic :: Topic -> BL.ByteString 
buildTopic e = runPut $  do 
  putWord16be $ topicNameLen e 
  putByteString $ topicName e
  putWord32be $ numPartitions e 
  putLazyByteString $ buildPartitions $ partitions e 

buildTopics :: [Topic] -> BL.ByteString
buildTopics [] = BL.empty 
buildTopics (x:xs) = BL.append (buildTopic x) (buildTopics xs)

buildProduceRequestMessage :: Request -> BL.ByteString
buildProduceRequestMessage e = runPut $ do 
  putWord16be $ reqRequiredAcks e
  putWord32be $ reqTimeout e 
  putWord32be $ reqNumTopics e 
  putLazyByteString $ buildTopics $ reqTopics e

buildRequestMessage :: RequestMessage -> BL.ByteString
buildRequestMessage e = runPut $ do 
  putWord32be $ reqSize e
  putWord16be $ reqApiKey e 
  putWord16be $ reqApiVersion e 
  putWord32be $ reqCorrelationId e 
  putWord16be $ reqClientIdLen e 
  putByteString $ reqClientId e 
  putLazyByteString $ buildProduceRequestMessage $ request e





