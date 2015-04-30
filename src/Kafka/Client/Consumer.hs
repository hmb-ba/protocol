module Kafka.Client.Consumer 
( encodeRequest
, decodeFtResponse
, packFtRqMessage
) where

import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Char8 as BC
import Data.Binary.Get
import Kafka.Protocol


packTopic :: BS.ByteString -> [Partition] -> Topic
packTopic t ps = Topic
   (RqTopicName (fromIntegral $ BS.length t) t)
   (fromIntegral $ length ps)
   ps
 
packFtRequest :: BS.ByteString -> Offset -> Request
packFtRequest t o = FetchRequest 
   (-1)
   0
   0
   1
   [packTopic t [packFtPartition o]]

packFtPartition ::Offset -> Partition 
packFtPartition o = RqFtPartition
   0
   o
   1048576

packFtRqMessage :: (Int, Int, String, String, Int) -> RequestMessage
packFtRqMessage (apiV, corr, client, topic, offset) = RequestMessage {
       rqSize = (fromIntegral $ (BL.length $ buildFetchRequest $ packFtRequest (BC.pack topic) (fromIntegral offset))
                              + 2 -- reqApiKey
                              + 2 -- reqApiVersion
                              + 4 -- correlationId 
                              + 2 -- clientIdLen
                              + (fromIntegral $ length client) -- clientId
                )
     , rqApiKey = 1
     , rqApiVersion = fromIntegral apiV
     , rqCorrelationId = fromIntegral corr
     , rqClientIdLen = fromIntegral $ length client
     , rqClientId = BC.pack client
     , rqRequest = packFtRequest (BC.pack topic) (fromIntegral offset)
  }

-------------------
-- Encode / Decode
-------------------

encodeRequest :: (Int, Int, Int, String, String, Int) -> RequestMessage
encodeRequest (1, apiV, corr, client, topic, offset) = packFtRqMessage (apiV, corr, client, topic, offset)

decodeFtResponse :: BL.ByteString -> ResponseMessage
decodeFtResponse b = runGet fetchResponseMessageParser b
