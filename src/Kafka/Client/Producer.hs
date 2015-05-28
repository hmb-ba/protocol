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
import Data.Binary.Put
import qualified Control.Exception as E

-- FIXME (meiersi): introduce at least type synonyms for the different kinds
-- of 'ByteString's in the arguments. Ideally, use 'Tagged' from
-- <http://hackage.haskell.org/package/tagged-0.8.0.1/docs/Data-Tagged.html>
-- to cheaply introduce /different/ types.
packPrRqMessage :: (BS.ByteString, BS.ByteString, Int, [BS.ByteString]) -> RequestMessage
packPrRqMessage (client, topic, partition, inputData) = RequestMessage {
      rqSize = fromIntegral $ (BL.length $ runPut $ buildProduceRequest produceRequest )
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
  -- FIXME (meiersi): the formatting of both the record above and the where
  -- clause below seems quite arbitrary. Have a look at 
  -- <https://github.com/tibbe/haskell-style-guide/blob/master/haskell-style.md>
  -- for a base set of rules that a lot of Haskell code is following.
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
                          (fromIntegral $ BL.length $ runPut $ buildMessageSets ms)
                          ms
        ms = (map packMessageSet inputData)

packMessageSet :: BS.ByteString -> MessageSet
packMessageSet bs = MessageSet
                          0
                          (fromIntegral $ BL.length $ runPut $ buildMessage packMessage)
                          packMessage
  where
        packMessage = Message
                          (crc32 $ runPut $ buildPayload packPayload)
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

