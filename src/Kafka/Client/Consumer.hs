module Kafka.Client.Consumer 
( packFtRequestMessage
 , sendFtRequest
 ,InputFt (..) 
) where

import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Char8 as BC
import Network.Socket
import qualified Network.Socket.ByteString.Lazy as SBL

import Kafka.Protocol.Types
import Kafka.Protocol.Serializer

data InputFt = InputFt
  { ftInputClientId        :: !ClientId,
    ftInputTopicName       :: !TopicName 
  }

packTopic :: BS.ByteString -> [Partition] -> Topic
packTopic t ps = Topic
   (fromIntegral $ BS.length t)
   t
   (fromIntegral $ length ps)
   ps
 
packFtRequest :: BS.ByteString -> Request
packFtRequest t = FetchRequest 
   0
   0
   0
   1
   [packTopic t [packFtPartition]]

packFtPartition ::Partition 
packFtPartition = RqFtPartition
   0
   0
   1048576

packFtRequestMessage :: InputFt -> RequestMessage
packFtRequestMessage iM = RequestMessage {
       rqSize = fromIntegral $ (BL.length $ buildFetchRequest $ packFtRequest $ ftInputTopicName iM )
           + 2 -- reqApiKey
           + 2 -- reqApiVersion
           + 4 -- correlationId 
           + 2 -- clientIdLen
           + (fromIntegral $ BS.length $ ftInputClientId iM) --clientId
     , rqApiKey = 0
     , rqApiVersion = 0
     , rqCorrelationId = 0
     , rqClientIdLen = fromIntegral $ BS.length $ ftInputClientId iM
     , rqClientId = ftInputClientId iM
     , rqRequest = (packFtRequest $ ftInputTopicName iM)
  }

sendFtRequest :: Socket -> RequestMessage -> IO() 
sendFtRequest socket requestMessage = do 
  let msg = buildFtRqMessage requestMessage
  SBL.sendAll socket msg


