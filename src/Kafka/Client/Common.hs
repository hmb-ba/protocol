module Kafka.Client.Common
( sendRequest
) where

import qualified Network.Socket.ByteString.Lazy as SBL
import Kafka.Protocol
import Network.Socket

sendRequest :: Socket -> RequestMessage -> IO()
sendRequest socket requestMessage = do
    SBL.sendAll socket msg
    where msg = case (rqApiKey requestMessage) of
                    0 -> buildPrRqMessage requestMessage
                    1 -> buildFtRqMessage requestMessage


