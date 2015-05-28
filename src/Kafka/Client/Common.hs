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


sendRequest :: Socket -> RequestMessage -> IO ()
sendRequest socket requestMessage = do
    SBL.sendAll socket msg
    where msg = case (rqApiKey requestMessage) of
                    0 -> buildPrRqMessage requestMessage
                    1 -> buildFtRqMessage requestMessage
                    3 -> buildMdRqMessage requestMessage

-- FIXME (meiersi): use 'Text' from the 'T.Text' library and 'encodeUtf8' to
-- create an API that uses sequences of Unicode characters for topic names.
--
-- However, I would suggest to isolate consumers from this fact by making
-- 'TopicName' an abstract type that uses an expressive enough representation
-- internally (B.ByteString probably). You can then expose a little API for
-- converting between 'TopicNames' and 'String', 'Text', etc., which properly
-- handles issues such as invalid characters in topic names like the ones that
-- lead to this problem <https://issues.apache.org/jira/browse/KAFKA-495>.
--
packTopicName :: [Char] -> RqTopicName
packTopicName t = RqTopicName (fromIntegral $ length t) (BC.pack t)

packTopicNames :: [[Char]] -> [RqTopicName]
packTopicNames ts = map packTopicName ts

-- FIXME (meiersi): these large tuple arguments are not idiomatic Haskell.
-- Replace them with either a Record for named arguments or individual
-- arguments, whose types are ideally different enough such that callers can
-- easily avoid mistakes in the positional arguments.
encodeMdRequest :: (Int, Int, [Char], [String] ) -> RequestMessage
encodeMdRequest (apiV, corr, client, ts) = RequestMessage
-- FIXME (meiersi): your indentation seems to be quite arbitrary. Try to adopt
-- an indentation style that is content-independent. This will allow you to
-- easily scale to more complex code without having to invent new rules all
-- the time.
-- <https://github.com/tibbe/haskell-style-guide/blob/master/haskell-style.md>
-- is a good start.
              (fromIntegral ((BL.length $ buildMetadataRequest $ (MetadataRequest (fromIntegral $ length ts) (packTopicNames ts))) + 2 + 2 + 4 + 2 + (fromIntegral $ length client)))
              3
              (fromIntegral apiV)
              (fromIntegral corr)
              (fromIntegral $ length client)
              (BC.pack client)
              (MetadataRequest (fromIntegral $ length ts) (packTopicNames ts))

decodeMdResponse :: BL.ByteString -> ResponseMessage
decodeMdResponse b = runGet metadataResponseMessageParser b
