module Kafka.Client.Producer
(  packPrRqMessage
 , decodePrResponse
)
where 

import Kafka.Protocol

import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import Data.Digest.CRC32
import Data.Binary.Get

import qualified Control.Exception as E 

packPrRqMessage :: (BS.ByteString, BS.ByteString, Int, [BS.ByteString]) -> RequestMessage
packPrRqMessage (client, topic, partition, inputData) = RequestMessage {
      rqSize = fromIntegral $ (BL.length $ buildProduceRequest produceRequest )
          + 2 -- reqApiKey
          + 2 -- reqApiVersion
          + 4 -- correlationId 
          + 2 -- clientIdLen
          + (fromIntegral $ BS.length client) --clientId
    , rqApiKey = 0
    , rqApiVersion = 0
    , rqCorrelationId = 0
    , rqClientIdLen = fromIntegral $ BS.length client
    , rqClientId = client
    , rqRequest = produceRequest
  }
  where produceRequest = ProduceRequest
                          0
                          1500
                          (fromIntegral $ length [packTopic])
                          [packTopic]
        packTopic = RqTopic
                          (fromIntegral $ BS.length topic) 
                          topic
                          (fromIntegral $ length [packPartition])
                          ([packPartition])
        packPartition = RqPrPartition
                          (fromIntegral partition)
                          (fromIntegral $ BL.length $ buildMessageSets ms)
                          ms
        ms = (map packMessageSet inputData)

packMessageSet :: BS.ByteString -> MessageSet
packMessageSet bs = MessageSet
                          0
                          (fromIntegral $ BL.length $ buildMessage packMessage)
                          packMessage
  where
        packMessage = Message
                          (crc32 $ buildPayload packPayload)
                          packPayload
        packPayload = Payload
                          0
                          0
                          0
                          (fromIntegral $ BS.length bs)
                          bs


-------------------
-- Encode / Decode
-------------------

decodePrResponse :: BL.ByteString -> ResponseMessage
decodePrResponse a = runGet produceResponseMessageParser a

