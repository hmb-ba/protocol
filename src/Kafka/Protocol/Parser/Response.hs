module Kafka.Protocol.Parser.Response
( produceResponseMessageParser
, fetchResponseMessageParser
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

---------------------
-- Produce Response (Pr)
---------------------
rsPrErrorParser :: Get RsPrError 
rsPrErrorParser= do 
  partitionNumber <- getWord32be
  errorCode <- getWord16be 
  offset <- getWord64be 
  return $! RsPrError partitionNumber errorCode offset

produceResponseParser :: Get Response
produceResponseParser = do 
  topicNameLen <- getWord16be
  topicsName <- getByteString $ fromIntegral topicNameLen
  numErrors <- getWord32be
  errors <- parseList (fromIntegral numErrors) rsPrErrorParser
  return $! ProduceResponse topicNameLen topicsName numErrors errors

produceResponseMessageParser :: Get ResponseMessage
produceResponseMessageParser = do 
  correlationId <- getWord32be 
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

rsFtPayloadParser :: Get RsFtPayload 
rsFtPayloadParser = do 
  partition <- getWord32be
  errorCode <- getWord16be
  hwMarkOffset <- getWord64be
  messageSetSize <- getWord32be
  messageSet <- parseMessageSets (fromIntegral messageSetSize)
  return $! RsFtPayload partition errorCode hwMarkOffset messageSetSize messageSet



