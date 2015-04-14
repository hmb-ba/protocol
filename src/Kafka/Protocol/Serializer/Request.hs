module Kafka.Protocol.Serializer.Request 
( 
  buildRequestMessage
, buildProduceRequestMessage
) where 

import Data.Binary.Put
import qualified Data.ByteString.Lazy as BL
import qualified Network.Socket.ByteString.Lazy as SBL
import Kafka.Protocol.Types
import Kafka.Protocol.Serializer.Data

buildList :: (a -> BL.ByteString) -> [a] -> BL.ByteString
buildList builder [] = BL.empty 
buildList builder (x:xs) = BL.append (builder x) (buildList builder xs)

buildRequestMessage :: RequestMessage -> BL.ByteString
buildRequestMessage e = runPut $ do 
  putWord32be $ rqSize e
  putWord16be $ rqApiKey e 
  putWord16be $ rqApiVersion e 
  putWord32be $ rqCorrelationId e 
  putWord16be $ rqClientIdLen e 
  putByteString $ rqClientId e 
  putLazyByteString $ buildProduceRequestMessage $ rqRequest e

-------------------------------
-- Produce Request
-------------------------------
buildMessageSets :: [MessageSet] -> BL.ByteString
buildMessageSets [] = BL.empty
buildMessageSets (x:xs) = BL.append (buildMessageSet x) (buildMessageSets xs)

buildRqPrPartition :: Partition -> BL.ByteString
buildRqPrPartition e = runPut $ do 
  putWord32be $ rqPrPartitionNumber e
  putWord32be $ rqPrMessageSetSize e
  putLazyByteString $ buildMessageSets $ rqPrMessageSet e

buildRqPrPartitions :: [Partition] -> BL.ByteString
buildRqPrPartitions [] = BL.empty
buildRqPrPartitions (x:xs) = BL.append (buildRqPrPartition x) (buildRqPrPartitions xs) 

buildRqPrTopic :: Topic -> BL.ByteString 
buildRqPrTopic e = runPut $  do 
  putWord16be $ topicNameLen e 
  putByteString $ topicName e
  putWord32be $ numPartitions e 
  putLazyByteString $ buildRqPrPartitions $ partitions e 

buildRqPrTopics :: [Topic] -> BL.ByteString
buildRqPrTopics [] = BL.empty 
buildRqPrTopics (x:xs) = BL.append (buildRqPrTopic x) (buildRqPrTopics xs)

buildProduceRequestMessage :: Request -> BL.ByteString
buildProduceRequestMessage e = runPut $ do 
  putWord16be $ rqPrRequiredAcks e
  putWord32be $ rqPrTimeout e 
  putWord32be $ rqPrNumTopics e 
  putLazyByteString $ buildRqPrTopics $ rqPrTopics e

-------------------------------
-- Fetch Request
-------------------------------
--TODO: 
--buildFetchRequestMessage :: Request -> BL.ByteString
--buildFetchRequestMessage e = runPut $ do 
--  putWord32be $ rqFtReplicaId e 
--  putWord32be $ rqFtMaxWaitTime e
--  putWord32be $ rqFtMinBytes e
--  putword32be $ rqFtNumTopics e 
--  putLazyByteString $ buildTopic



