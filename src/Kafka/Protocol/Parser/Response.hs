module Kafka.Protocol.Parser.Response
(
  produceResponseMessageParser
) where 

import Kafka.Protocol.Types
import Data.Binary.Get
import qualified Data.ByteString.Lazy as BL

errorParser :: Get Error 
errorParser = do 
  partitionNumber <- getWord32be
  errorCode <- getWord16be 
  offset <- getWord64be 
  return $! Error partitionNumber errorCode offset

getErrors :: Int -> Get [Error]
getErrors i = do 
  if (i < 1)
    then return []
    else do error <- errorParser 
            errors <- getErrors $ i-1
            return (error:errors)

produceResponseParser :: Get Response
produceResponseParser = do 
  topicNameLen <- getWord16be
  topicsName <- getByteString $ fromIntegral topicNameLen
  numErrors <- getWord32be
  errors <- getErrors $ fromIntegral numErrors
  return $! ProduceResponse topicNameLen topicsName numErrors errors

getProduceResponses :: Int -> Get [Response]
getProduceResponses i = do 
  if (i < 1) 
    then return []
    else do response <- produceResponseParser 
            responses <- getProduceResponses $ i-1
            return (response:responses)

produceResponseMessageParser :: Get ResponseMessage
produceResponseMessageParser = do 
  correlationId <- getWord32be 
  numResponses <- getWord32be
  responses <- getProduceResponses $ fromIntegral numResponses
  return $! ResponseMessage correlationId numResponses responses


