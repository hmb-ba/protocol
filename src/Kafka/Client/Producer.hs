{-# LANGUAGE ScopedTypeVariables #-}
module Kafka.Client.Producer
(  packPrRqMessage
 , decodePrResponse
 , decodePrResponse'
)
where 

import Kafka.Protocol

import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Char8 as BC
import Data.Digest.CRC32
import Data.Binary.Get

import qualified Control.Exception as E 

packPrRqMessage :: (String, String, Int, String) -> RequestMessage
packPrRqMessage (client, topic, partition, inputData) = RequestMessage {
      rqSize = fromIntegral $ (BL.length $ buildProduceRequest produceRequest )
          + 2 -- reqApiKey
          + 2 -- reqApiVersion
          + 4 -- correlationId 
          + 2 -- clientIdLen
          + (fromIntegral $ length client) --clientId
    , rqApiKey = 0
    , rqApiVersion = 0
    , rqCorrelationId = 0
    , rqClientIdLen = fromIntegral $ length client
    , rqClientId = BC.pack client
    , rqRequest = produceRequest
  }
  where produceRequest = ProduceRequest
                          0
                          1500
                          (fromIntegral $ length [packTopic])
                          [packTopic]
        packTopic = Topic
                          (fromIntegral $ length topic)
                          (BC.pack topic)
                          (fromIntegral $ length [packPartition])
                          ([packPartition])
        packPartition = RqPrPartition
                          (fromIntegral partition)
                          (fromIntegral $ BL.length $ buildMessageSet packMessageSet)
                          [packMessageSet]
        packMessageSet = MessageSet
                          0
                          (fromIntegral $ BL.length $ buildMessage packMessage)
                          packMessage
        packMessage = Message
                          (crc32 $ buildPayload packPayload)
                          packPayload
        packPayload = Payload
                          0
                          0
                          0
                          (fromIntegral $ length inputData)
                          (BC.pack inputData)


-------------------
-- Encode / Decode
-------------------

decodePrResponse :: BL.ByteString -> ResponseMessage
decodePrResponse a = runGet produceResponseMessageParser a

decodePrResponse' :: BL.ByteString -> IO(Either String RequestMessage)
decodePrResponse' a = 
  E.catch (E.evaluate $ Right $ runGet requestMessageParser a) ( \(e :: E.SomeException) -> return (Left "Err"))
