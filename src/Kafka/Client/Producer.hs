module Kafka.Client.Producer
(  packRequest
 , sendRequest
 , readProduceResponse
 , InputMessage (..)
)
where 

import Network.Socket

import Kafka.Protocol

import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL

import Data.Digest.CRC32
import qualified Network.Socket.ByteString.Lazy as SBL

import Data.Binary.Get 

data InputMessage = InputMessage
  { inputClientId        :: !ClientId
  , inputTopicName       :: !TopicName
  , inputPartitionNumber :: !PartitionNumber
  , inputData            :: !BS.ByteString
}

packRequest :: InputMessage -> RequestMessage
packRequest iM = 
  let payload = Payload
        0
        0
        0
        (fromIntegral $ BS.length $ inputData iM)
        (inputData iM)
  
  in
  let message = Message
        (crc32 $ buildPayload payload)
        payload
  
  in
  let messageSet = MessageSet
        0
        (fromIntegral $ BL.length $ buildMessage message)
        message
  
  in
  let partition = RqPrPartition
        (inputPartitionNumber iM)
        (fromIntegral $ BL.length $ buildMessageSet messageSet)
        [messageSet]
  
  in
  let topic = Topic
        (fromIntegral $ BS.length $ inputTopicName iM)
        (inputTopicName iM)
        (fromIntegral $ length [partition])
        ([partition])
  
  in
  let produceRequest = ProduceRequest
        0
        1500
        (fromIntegral $ length [topic])
        [topic]
  
  in
  let requestMessage = RequestMessage {
      rqSize = fromIntegral $ (BL.length $ buildProduceRequestMessage produceRequest )
          + 2 -- reqApiKey
          + 2 -- reqApiVersion
          + 4 -- correlationId 
          + 2 -- clientIdLen
          + (fromIntegral $ BS.length $ inputClientId iM) --clientId
    , rqApiKey = 0
    , rqApiVersion = 0
    , rqCorrelationId = 0
    , rqClientIdLen = fromIntegral $ BS.length $ inputClientId iM
    , rqClientId = inputClientId iM
    , rqRequest = produceRequest
  }
  in
  requestMessage

sendRequest :: Socket -> RequestMessage -> IO() 
sendRequest socket requestMessage = do 
  let msg = buildRequestMessage requestMessage
  SBL.sendAll socket msg

readProduceResponse :: BL.ByteString -> IO ResponseMessage
readProduceResponse a =  do 
  return (runGet produceResponseMessageParser a)

