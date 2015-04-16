module Kafka.Protocol.Serializer.Response
( buildPrResponseMessage
, buildFtRsMessage
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
  putWord32be       $ rsNumResponses rm
  putLazyByteString $ buildList rsBuilder $ rsResponses rm

--------------------
-- Produce Response (Pr)
--------------------
buildRsPrError :: RsPrError -> BL.ByteString 

buildRsPrError e = runPut $ do 
  putWord32be $ rsPrPartitionNumber e
  putWord16be $ rsPrCode e 
  putWord64be $ rsPrOffset e 

buildRsPrErrors :: [RsPrError] -> BL.ByteString
buildRsPrErrors [] = BL.empty
buildRsPrErrors (x:xs) = BL.append (buildRsPrError x) (buildRsPrErrors xs)

buildProduceResponse :: Response -> BL.ByteString
buildProduceResponse e = runPut $ do 
  putWord16be $ rsPrTopicNameLen e 
  putByteString $ rsPrTopicName e
  putWord32be $ rsPrNumErrors e 
  putLazyByteString $ buildRsPrErrors $ rsPrErrors e

buildProduceResponses :: [Response] -> BL.ByteString
buildProduceResponses [] = BL.empty 
buildProduceResponses (x:xs) = BL.append (buildProduceResponse x) (buildProduceResponses xs)

buildPrResponseMessage :: ResponseMessage -> BL.ByteString
buildPrResponseMessage e = runPut $ do 
  putWord32be $ rsCorrelationId e 
  putWord32be $ rsNumResponses e 
  putLazyByteString $ buildProduceResponses $ rsResponses e 

--------------------
-- FetchResponse
--------------------
buildFtPayload :: RsFtPayload -> BL.ByteString
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

