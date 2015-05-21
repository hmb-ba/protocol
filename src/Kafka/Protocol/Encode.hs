module Kafka.Protocol.Encode
(
  buildMessageSet
, buildMessage
, buildPayload

, buildRqMessage
, buildMessageSets
, buildProduceRequest
, buildPrRqMessage
, buildFetchRequest
, buildFtRqMessage
, buildMdRqMessage
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


--------------------------------------------------------
-- Common
--------------------------------------------------------

buildList :: (a -> BL.ByteString) -> [a] -> BL.ByteString
buildList builder [] = BL.empty 
buildList builder (x:xs) = BL.append (builder x) (buildList builder xs)

--------------------------------------------------------
-- Data
--------------------------------------------------------

buildMessageSet :: MessageSet -> BL.ByteString
buildMessageSet e = runPut $ do 
  putWord64be $ offset e
  putWord32be $ len e
  putLazyByteString $ buildMessage $ message e

buildMessage :: Message -> BL.ByteString
buildMessage e = runPut $ do 
  --putWord32be $ crc32 $ payloadData $ payload e
  putWord32be $ crc e
  putLazyByteString $ buildPayload $ payload e 

buildPayload :: Payload -> BL.ByteString 
buildPayload e = runPut $ do 
  putWord8    $ magic e
  putWord8    $ attr e
  putWord32be $ keylen $ e
  putWord32be $ payloadLen $ e
  putByteString $ payloadData $ e



--------------------------------------------------------
-- Request
--------------------------------------------------------


buildRqMessage :: RequestMessage -> (Request -> BL.ByteString) -> BL.ByteString
buildRqMessage e rb = runPut $ do 
  putWord32be $ rqSize e
  putWord16be $ rqApiKey e 
  putWord16be $ rqApiVersion e 
  putWord32be $ rqCorrelationId e 
  putWord16be $ rqClientIdLen e 
  putByteString $ rqClientId e 
  putLazyByteString $ rb $ rqRequest e

buildTopic :: (Partition -> BL.ByteString) -> RqTopic -> BL.ByteString
buildTopic pb t = runPut $ do
  putWord16be         $ rqTopicNameLen t
  putByteString       $ rqTopicName t 
  putWord32be       $ numPartitions t
  putLazyByteString $ foldl (\acc p -> BL.append acc (pb p)) BL.empty $ partitions t

buildRqTopicName :: RqTopicName -> BL.ByteString
buildRqTopicName e = runPut $ do
  putWord16be         $ topicNameLen e
  putByteString       $ topicName e 

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

buildProduceRequest :: Request -> BL.ByteString
buildProduceRequest e = runPut $ do 
  putWord16be $ rqPrRequiredAcks e
  putWord32be $ rqPrTimeout e 
  putWord32be $ rqPrNumTopics e 
  putLazyByteString $ foldl (\acc t -> BL.append acc (buildTopic buildRqPrPartition t)) BL.empty $ rqPrTopics e

buildPrRqMessage :: RequestMessage -> BL.ByteString
buildPrRqMessage rm = buildRqMessage rm buildProduceRequest

-------------------------------
-- Fetch Request
-------------------------------

buildRqFtPartition :: Partition -> BL.ByteString
buildRqFtPartition p = runPut $ do
  putWord32be $ rqFtPartitionNumber p
  putWord64be $ rqFtFetchOffset p
  putWord32be $ rqFtMaxBytes p

buildFetchRequest :: Request -> BL.ByteString
buildFetchRequest e = runPut $ do 
  putWord32be $ rqFtReplicaId e 
  putWord32be $ rqFtMaxWaitTime e
  putWord32be $ rqFtMinBytes e
  putWord32be $ rqFtNumTopics e 
  putLazyByteString $ foldl (\acc t -> BL.append acc (buildTopic buildRqFtPartition t)) BL.empty $ rqFtTopics e

buildFtRqMessage :: RequestMessage -> BL.ByteString
buildFtRqMessage rm = buildRqMessage rm buildFetchRequest

-------------------------------
-- Metadata Request
-------------------------------
buildMetadataRequest :: Request -> BL.ByteString 
buildMetadataRequest e = runPut $ do 
  putWord32be $ rqMdNumTopics e 
  putLazyByteString $ foldl (\acc t -> BL.append acc (buildRqTopicName t)) BL.empty $ rqMdTopicNames e

buildMdRqMessage :: RequestMessage -> BL.ByteString
buildMdRqMessage rm = buildRqMessage rm buildMetadataRequest

-------------------------------
-- Offset Request
-------------------------------
buildRqOfPartition :: Partition -> BL.ByteString
buildRqOfPartition e = runPut $ do 
  putWord32be     $ rqOfPartitionNumber e 
  putWord64be     $ rqOfTime e 
  putWord32be     $ rqOfMaxNumOffset e

buildOffsetRequest :: Request -> BL.ByteString 
buildOffsetRequest e = runPut $ do 
  putWord32be     $ rqOfReplicaId e 
  putWord32be     $ rqOfNumTopics e
  putLazyByteString $ foldl (\acc t -> BL.append acc (buildTopic buildRqOfPartition t)) BL.empty $ rqOfTopics e

buildOfRqMessage :: RequestMessage -> BL.ByteString
buildOfRqMessage rm = buildRqMessage rm buildOffsetRequest 



--------------------------------------------------------
-- Response
--------------------------------------------------------


buildRsMessage :: (Response -> BL.ByteString) -> ResponseMessage -> BL.ByteString
buildRsMessage rsBuilder rm = runPut $ do
  putWord32be       $ rsCorrelationId rm
  putWord32be       $ fromIntegral 0  --TODO: Unkown Word32 from original kafka response
  putWord32be       $ rsNumResponses rm
  putLazyByteString $ buildList rsBuilder $ rsResponses rm

buildRsTopic :: (RsPayload -> BL.ByteString) -> RsTopic -> BL.ByteString 
buildRsTopic b t = runPut $ do 
  putWord16be $ rsTopicNameLen t 
  putByteString $ rsTopicName t
  putWord32be $ rsNumPayloads t 
  putLazyByteString $ foldl(\acc p -> BL.append acc (b p)) BL.empty $ rsPayloads t

--------------------
-- Produce Response (Pr)
--------------------
buildRsPrPayload :: RsPayload -> BL.ByteString 
buildRsPrPayload e = runPut $ do 
  putWord32be $ rsPrPartitionNumber e
  putWord16be $ rsPrCode e 
  putWord64be $ rsPrOffset e 

buildProduceResponse :: Response -> BL.ByteString
buildProduceResponse e = runPut $ do 
  putLazyByteString $ buildRsTopic buildRsPrPayload $ rsPrTopic e 

buildPrResponseMessage :: ResponseMessage -> BL.ByteString
buildPrResponseMessage rm = buildRsMessage buildProduceResponse rm

--------------------
-- Fetch Response (Ft)
--------------------
buildFtPayload :: RsPayload -> BL.ByteString
buildFtPayload p = runPut $ do 
  putWord32be       $ rsFtPartitionNumber p
  putWord16be       $ rsFtErrorCode p
  putWord64be       $ rsFtHwMarkOffset p
  putWord32be       $ rsFtMessageSetSize p
  putLazyByteString $ foldl (\acc ms -> BL.append acc (buildMessageSet ms)) BL.empty $ rsFtMessageSets p


buildFtRs :: Response -> BL.ByteString
buildFtRs rs = runPut $ do
  putWord16be       $ rsFtTopicNameLen rs
  putLazyByteString $ BL.fromStrict(rsFtTopicName rs)
  putWord32be       $ rsFtNumsPayloads rs
  putLazyByteString $ buildList buildFtPayload $ rsFtPayloads rs

buildFtRsMessage :: ResponseMessage -> BL.ByteString
buildFtRsMessage rm = buildRsMessage buildFtRs rm

--------------------
-- Offset Response (Of)
--------------------
buildRsOfPartitionOf :: RsOfPartitionOf -> BL.ByteString
buildRsOfPartitionOf p = runPut $ do 
  putWord32be     $ rsOfPartitionNumber p
  putWord64be     $ rsOfErrorCode p
  putWord32be     $ rsOfNumOffsets p
  putLazyByteString $ foldl (\acc o -> BL.append acc (runPut $ putWord64be $ o)) BL.empty $ rsOfOffsets p

buildOfRs :: Response -> BL.ByteString
buildOfRs rs = runPut $ do 
  putWord16be       $ rsOfTopicNameLen rs
  putLazyByteString $ BL.fromStrict(rsOfTopicName rs) 
  putWord32be       $ rsOfNumPartitionOfs rs 
  putLazyByteString $ foldl (\acc p -> BL.append acc (buildRsOfPartitionOf p)) BL.empty $ rsOfPartitionOfs rs

buildOfRsMessage :: ResponseMessage -> BL.ByteString
buildOfRsMessage rm = buildRsMessage buildOfRs rm 

--------------------
-- Metadata Response (Md)
--------------------
buildRsMdPartitionMetadata :: RsMdPartitionMetadata -> BL.ByteString
buildRsMdPartitionMetadata p = runPut $ do 
  putWord16be   $ rsMdPartitionErrorCode p
  putWord32be   $ rsMdPartitionId p
  putWord32be   $ rsMdLeader p
  putWord32be   $ rsMdNumReplicas p 
  putLazyByteString $ foldl (\acc r -> BL.append acc (runPut $ putWord32be r)) BL.empty $ rsMdReplicas p 
  putWord32be  $ rsMdNumIsrs p 
  putLazyByteString $ foldl (\acc r -> BL.append acc (runPut $ putWord32be r)) BL.empty $ rsMdIsrs p

buildRsMdPayloadTopic :: RsPayload -> BL.ByteString
buildRsMdPayloadTopic t = runPut $ do 
  putWord16be   $ rsMdTopicErrorCode t
  putWord16be   $ rsMdTopicNameLen t
  putLazyByteString $ BL.fromStrict $ rsMdTopicName t
  putWord32be   $ rsMdNumPartitionMd t
  putLazyByteString $ foldl (\acc p -> BL.append acc (buildRsMdPartitionMetadata p)) BL.empty $ rsMdPartitionMd t

buildRsMdPayloadBroker :: RsPayload -> BL.ByteString
buildRsMdPayloadBroker p = runPut $ do 
  putWord32be    $ rsMdNodeId p 
  putWord16be    $ rsMdHostLen p
  putLazyByteString $ BL.fromStrict(rsMdHost p)
  putWord32be   $ rsMdPort p

buildMdRs :: Response -> BL.ByteString
buildMdRs rs = runPut $ do 
  putWord32be     $  rsMdNumBroker rs
  putLazyByteString $ foldl (\acc b -> BL.append acc (buildRsMdPayloadBroker b)) BL.empty $ rsMdBrokers rs
  putWord32be     $ rsMdNumTopicMd rs 
  putLazyByteString $ foldl (\acc b -> BL.append acc (buildRsMdPayloadTopic b)) BL.empty $ rsMdTopicMetadata rs

buildMdRsMessage :: ResponseMessage -> BL.ByteString
buildMdRsMessage rm = buildRsMessage buildMdRs rm 


