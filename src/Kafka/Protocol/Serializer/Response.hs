module Kafka.Protocol.Serializer.Response
( buildPrResponseMessage
, buildFtRsMessage
, buildMdRsMessage
) where 

import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import qualified Network.Socket.ByteString.Lazy as SBL
import Network.Socket
import Data.Binary.Put
import Kafka.Protocol.Types
import Kafka.Protocol.Serializer.Data


buildList :: (a -> BL.ByteString) -> [a] -> BL.ByteString
buildList builder [] = BL.empty 
buildList builder (x:xs) = BL.append (builder x) (buildList builder xs)

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

