{- |
Module      :  Kafka.Client
Description :  Client library of HMB/Apache Kafka
Copyright   :  (c) Marc Juchli, Lorenz Wolf
License     :
Maintainer  :  mail@marcjuch.li, lorenz.wolf@bluewin.ch
Stability   :  experimental
Portability :  portable

Provides simplified abstraction of the protocol types and allows to send
Apache Kafka compatible requests over sockets. Additionally exposes functions
to decode response messages.

-}
module Kafka.Client
    ( sendRequest
    , packPrRqMessage
    , packFtRqMessage
    , decodePrResponse
    , decodeFtResponse
    , decodeMdResponse
    , Data (..)
    , T (..)
    , P (..)
    , stringToTopic
    , textToTopic
    , stringToClientId
    , textToClientId
    ) where

import Kafka.Protocol

import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Char8 as BC
import qualified Data.ByteString.Lazy.Char8 as C
import Data.Digest.CRC32
import Data.Binary.Get
import Data.Binary.Put
import Data.Tagged

import qualified Control.Exception as E

import qualified Data.Text as T
import Data.Text.Encoding

import Network.Socket
import qualified Network.Socket.ByteString.Lazy as SBL
-------------------
--Send Functions
------------------
sendRequest :: Socket -> RequestMessage -> IO ()
sendRequest socket requestMessage = do
    SBL.sendAll socket msg
    where msg = runPut $ buildRqMessage requestMessage

-- FIXME (meiersi): use 'Text' from the 'T.Text' library and 'encodeUtf8' to
-- create an API that uses sequences of Unicode characters for topic names.
--
-- However, I would suggest to isolate consumers from this fact by making
-- 'TopicName' an abstract type that uses an expressive enough representation
-- internally (B.ByteString probably). You can then expose a little API for
-- converting between 'TopicNames' and 'String', 'Text', etc., which properly
-- handles issues such as invalid characters in topic names like the ones that
-- lead to this problem <https://issues.apache.org/jira/browse/KAFKA-495>.
--data Topic a = TopicB BS.ByteString | TopicS String | TopicT T.Text

--------------------
--Types
-------------------
data Data = Data [T]
data T = T (TopicName' BS.ByteString) [P]
data P = P Int [M]
type M = BS.ByteString

data TopicName' a = TopicName' BS.ByteString
data Client a = Client BS.ByteString

----------------
-- Converting API
----------------
stringToTopic :: String -> TopicName' a
stringToTopic s = TopicName' $ BC.pack s

textToTopic :: T.Text -> TopicName' a
textToTopic t = TopicName' $ encodeUtf8 t

stringToClientId :: String -> Client a
stringToClientId s = Client $ BC.pack s

textToClientId :: T.Text -> Client a
textToClientId t = Client $ encodeUtf8 t

--------------------
--Pack Functions
--------------------
-- FIXME (meiersi): the formatting of both the record above and the where
-- clause below seems quite arbitrary. Have a look at
-- <https://github.com/tibbe/haskell-style-guide/blob/master/haskell-style.md>
-- for a base set of rules that a lot of Haskell code is following.
packPrRqMessage :: Client BS.ByteString -> Data -> RequestMessage
packPrRqMessage (Client client) (Data ts)  = RequestMessage
  { rqSize = fromIntegral $ (BL.length $ runPut $ buildProduceRequest produceRequest )
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
  where
    produceRequest = ProduceRequest
                          0
                          1500
                          (fromIntegral $ length $ pts ts)
                          (pts ts)
    pts ts = (map packTopic $ ts)
    packTopic (T (TopicName' t) ps) = RqTopic
                          (fromIntegral $ BS.length $ t)
                          t
                          (fromIntegral $ length $ pps ps)
                          (pps ps)
    pps ps = (map packPartition ps)
    packPartition (P i ms) = RqPrPartition
                          (fromIntegral $ i)
                          (fromIntegral $ BL.length $ runPut $ buildMessageSets $ pms ms)
                          (pms ms)
    pms ms = (map packMessageSet $ ms)
    packMessageSet bs = MessageSet
                          0
                          (fromIntegral $ BL.length $ runPut $ buildMessage $ packMessage bs)
                          (packMessage bs)
    packMessage bs = Message
                          (crc32 $ runPut $ buildPayload $ packPayload bs)
                          (packPayload bs)
    packPayload bs = Payload
                          0
                          0
                          0
                          (fromIntegral $ BS.length bs)
                          bs

packTopicName :: [Char] -> RqTopicName
packTopicName t = RqTopicName (fromIntegral $ length t) (BC.pack t)

packTopicNames :: [[Char]] -> [RqTopicName]
packTopicNames ts = map packTopicName ts

-- FIXME (meiersi): these large tuple arguments are not idiomatic Haskell.
-- Replace them with either a Record for named arguments or individual
-- arguments, whose types are ideally different enough such that callers can
-- easily avoid mistakes in the positional arguments.
packMdRequest :: (Int, Int, [Char], [String] ) -> RequestMessage
packMdRequest (apiV, corr, client, ts) = RequestMessage
-- FIXME (meiersi): your indentation seems to be quite arbitrary. Try to adopt
-- an indentation style that is content-independent. This will allow you to
-- easily scale to more complex code without having to invent new rules all
-- the time.
-- <https://github.com/tibbe/haskell-style-guide/blob/master/haskell-style.md>
-- is a good start.
              (fromIntegral ((BL.length $ runPut $ buildMetadataRequest $ (MetadataRequest (fromIntegral $ length ts) (packTopicNames ts))) + 2 + 2 + 4 + 2 + (fromIntegral $ length client)))
              3
              (fromIntegral apiV)
              (fromIntegral corr)
              (fromIntegral $ length client)
              (BC.pack client)
              (MetadataRequest (fromIntegral $ length ts) (packTopicNames ts))

decodeMdResponse :: BL.ByteString -> ResponseMessage
decodeMdResponse b = runGet metadataResponseMessageParser b



decodePrResponse :: BL.ByteString -> ResponseMessage
decodePrResponse a = runGet produceResponseMessageParser a

---------------------
--Consumer Client API
--------------------
packTopic :: BS.ByteString -> [Partition] -> RqTopic
packTopic t ps = RqTopic
    (fromIntegral $ BS.length t)
    t
    (fromIntegral $ length ps)
    ps

packFtRequest :: BS.ByteString -> PartitionNumber -> Offset -> Request
packFtRequest t p o = FetchRequest
    (-1)
    0
    0
    1
    [packTopic t [packFtPartition p o]]

packFtPartition :: PartitionNumber -> Offset -> Partition
packFtPartition p o = RqFtPartition
    p
    o
    1048576

packFtRqMessage :: (Int, Int, [Char], [Char], Int, Int) -> RequestMessage
packFtRqMessage (apiV, corr, client, topic, partition, offset) = RequestMessage {
     -- FIXME (meiersi): this line seems to be unnecessarily long. Introduce
     -- local definitions in where clause that have telling names. Also
     -- consider adding explicit type signatures, as the 'fromIntegral'
     -- casting introduces a lot of uncertainty about what is really going
     -- on.
     rqSize = (fromIntegral $ (BL.length $ runPut $ buildFetchRequest $ packFtRequest (BC.pack topic) (fromIntegral partition) (fromIntegral offset))
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
   , rqRequest = packFtRequest (BC.pack topic) (fromIntegral partition) (fromIntegral offset)
  }

-------------------
-- Encode / Decode
-------------------

-- FIXME (meiersi): avoid partial functions!
-- FIXME (meiersi): replace magic tuple by a properly named record.
--encodeFtRequest :: (Int, Int, Int, String, String, Int, Int) -> RequestMessage
--encodeFtRequest (1, apiV, corr, client, topic, partition, offset) = packFtRqMessage (apiV, corr, client, topic, partition, offset)

decodeFtResponse :: BL.ByteString -> ResponseMessage
decodeFtResponse b = runGet fetchResponseMessageParser b
