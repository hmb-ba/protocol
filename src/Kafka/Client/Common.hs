module Kafka.Client.Common
( sendRequest
, encodeMdRequest
, decodeMdResponse
) where

import qualified Network.Socket.ByteString.Lazy as SBL
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Char8 as BC
import Kafka.Protocol
import Network.Socket
import Data.Binary.Get


sendRequest :: Socket -> RequestMessage -> IO()
sendRequest socket requestMessage = do
    SBL.sendAll socket msg
    where msg = case (rqApiKey requestMessage) of
                    0 -> buildPrRqMessage requestMessage
                    1 -> buildFtRqMessage requestMessage
                    3 -> buildMdRqMessage requestMessage 

packTopicName :: [Char] -> RqTopicName
packTopicName t = RqTopicName (fromIntegral $ length t) (BC.pack t)

packTopicNames :: [[Char]] -> [RqTopicName]
packTopicNames ts = map packTopicName ts

encodeMdRequest :: (Int, Int, [Char], [String] ) -> RequestMessage
encodeMdRequest (apiV, corr, client, ts) = RequestMessage
              (fromIntegral ((BL.length $ buildMetadataRequest $ (MetadataRequest (fromIntegral $ length ts) (packTopicNames ts))) + 2 + 2 + 4 + 2 + (fromIntegral $ length client)))
              3
              (fromIntegral apiV)
              (fromIntegral corr)
              (fromIntegral $ length client)
              (BC.pack client)
              (MetadataRequest (fromIntegral $ length ts) (packTopicNames ts))

decodeMdResponse :: BL.ByteString -> ResponseMessage 
decodeMdResponse b = runGet metadataResponseMessageParser b
