module Kafka.Client.Consumer 
( encodeRequest
, sendFtRequest
, readFtResponse
,InputFt (..) 
) where

import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Char8 as BC
import Network.Socket
import qualified Network.Socket.ByteString.Lazy as SBL
import Data.Binary.Get
import Kafka.Protocol

data InputFt = InputFt
  { ftInputClientId        :: !ClientId,
    ftInputTopicName       :: !TopicName, 
    ftInputFetchOffset     :: !Offset
  }

packTopic :: BS.ByteString -> [Partition] -> Topic
packTopic t ps = Topic
   (fromIntegral $ BS.length t)
   t
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

-- this should take all neccessary arguments to build a RequestMessage (excl. len ect)
encodeRequest :: (Int, Int, Int, String, String, Int) -> RequestMessage
encodeRequest (1, apiV, corr, client, topic, offset) = packFtRqMessage (apiV, corr, client, topic, offset)

sendFtRequest :: Socket -> RequestMessage -> IO()
sendFtRequest socket requestMessage = do
    SBL.sendAll socket msg
    where msg = case (rqApiKey requestMessage) of
                    1 -> buildFtRqMessage requestMessage

readFtResponse :: BL.ByteString -> ResponseMessage
readFtResponse b = runGet fetchResponseMessageParser b
