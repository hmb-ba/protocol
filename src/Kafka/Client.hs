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
( Req (..)
, Head (..)
, ToTopic (..)
, ToPart (..)
, FromTopic (..)
, FromPart (..)
, OfTopic (..)
, sendRequest
, decodePrResponse
, decodeFtResponse
, decodeMdResponse
, stringToTopic
, textToTopic
, stringToClientId
, textToClientId
, stringToData
, textToData
) where

import qualified Control.Exception as E

import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Char8 as BC
import qualified Data.ByteString.Lazy.Char8 as C
import Data.Binary.Get
import Data.Binary.Put
import Data.Digest.CRC32
import qualified Data.Text as T
import Data.Text.Encoding
import Data.Word

import Kafka.Protocol

import Network.Socket
import qualified Network.Socket.ByteString.Lazy as SBL

----------------
-- Types
----------------

-- | Pack and encode given Request of Type Req and send via given socket
sendRequest :: Socket -> Req -> IO ()
sendRequest socket req = do
    print $ show $ BL.length msg
    SBL.sendAll socket msg
    where msg = runPut $ buildRqMessage $ pack req

-- | Request Type
data Req = Produce Head [ToTopic] | Fetch Head [FromTopic] | Metadata Head [OfTopic]

class Packable a where
  pack :: a -> RequestMessage

instance Packable Req where
  pack (Produce head ts) = packPrRqMessage head ts
  pack (Fetch head ts) = packFtRqMessage head ts
  pack (Metadata head ts) = packMdRqMessage head ts

-- | Header information each request includes
data Head = Head
  { apiV      :: Int
  , corr      :: Int
  , client    :: BS.ByteString
  }

-- | Topic for Produce Request
data ToTopic = ToTopic BS.ByteString [ToPart]
-- | Partition for Produce Request
data ToPart = ToPart Int [Data]
type Data = BS.ByteString

-- | Topic for Fetch Request
data FromTopic = FromTopic BS.ByteString [FromPart]
-- | Partition for Fetch Request
data FromPart = FromPart
  { partId    :: Int
  , offset    :: Int
  }

-- | Topic for Metadata Request
data OfTopic = OfTopic BS.ByteString

----------------
-- Converting API
----------------

-- | Convert string to topicsName (ByteString)
stringToTopic :: String -> BS.ByteString
stringToTopic s = BC.pack s

-- | Convert Data.Text to topicsName (ByteString)
textToTopic :: T.Text -> BS.ByteString
textToTopic t = encodeUtf8 t

-- | Convert string to clientId (ByteString)
stringToClientId :: String -> BS.ByteString
stringToClientId s = BC.pack s

-- | Convert Data.Text to clientId (ByteString)
textToClientId :: T.Text -> BS.ByteString
textToClientId t = encodeUtf8 t

-- | Convert string to message data (ByteString)
stringToData :: String -> BS.ByteString
stringToData s = BC.pack s

-- | Convert Data.Text to message data (ByteString)
textToData :: T.Text -> BS.ByteString
textToData t = encodeUtf8 t

encodedLength :: Put -> Word32
encodedLength p = fromIntegral $ BL.length $ runPut p

byteLength :: BS.ByteString -> Word32
byteLength b = fromIntegral $ BS.length b

stringLength :: BS.ByteString -> Word16
stringLength b = fromIntegral $ BS.length b

arrayLength :: [a] -> Word32
arrayLength xs = fromIntegral $ length xs

--------------------
--Pack Functions
--------------------

-- | Pack a protocol conform RequestMessage for Produce API
packPrRqMessage :: Head -> [ToTopic] -> RequestMessage
packPrRqMessage head ts = RequestMessage
  -- FIXME (SM): I wager that downstream consumers of this function are
  -- going to call 'buildProduceRequest' again. This unnecessarily duplicates
  -- the work. I'd suggest that you restructure the code such that the request
  -- is built at most once, or if this is not possible I'd suggest to
  -- introduce special functions that compute the length of the message
  -- *without* computing the actual sequence of bytes.
  { rqSize = (encodedLength $ buildProduceRequest produceRequest)
          + 2 -- reqApiKey
          + 2 -- reqApiVersion
          + 4 -- correlationId
          + 2 -- clientIdLen
          + (byteLength $ client head ) --clientId
    , rqApiKey          = 0
    , rqApiVersion      = fromIntegral $ apiV head
    , rqCorrelationId   = fromIntegral $ corr head
    , rqClientIdLen     = stringLength $ client head
    , rqClientId        = client head
    , rqRequest         = produceRequest
  }
  where
    produceRequest = ProduceRequest
          0
          1500
          (fromIntegral $ length $ pts)
          (pts)
    pts = (map packTopic $ ts)
    packTopic (ToTopic t ps) = RqTopic
          (stringLength $ t)
          t
          (fromIntegral $ length $ pps ps)
          (pps ps)
    pps ps = (map packPartition ps)
    packPartition (ToPart i ms) = RqPrPartition
          (fromIntegral $ i)
          (encodedLength $ buildMessageSets $ pms ms)
          (pms ms)
    pms ms = (map packMessageSet ms)
    packMessageSet bs = MessageSet
          0
          (encodedLength $ buildMessage $ packMessage bs)
          (packMessage bs)
    packMessage bs = Message
          (crc32 $ runPut $ buildPayload $ packPayload bs)
          (packPayload bs)
    packPayload bs = Payload
          0
          0
          0 -- Key
          (fromIntegral $ BS.length bs)
          bs

-- | Pack a protocol conform RequestMessage for Fetch API
packFtRqMessage :: Head -> [FromTopic] -> RequestMessage
packFtRqMessage head ts = RequestMessage
  { rqSize = (encodedLength $ buildFetchRequest $ packFtRequest)
          + 2 -- reqApiKey
          + 2 -- reqApiVersion
          + 4 -- correlationId
          + 2 -- clientIdLen
          + (byteLength $ client head)
    , rqApiKey = 1
    , rqApiVersion = fromIntegral $ apiV head
    , rqCorrelationId = fromIntegral $ corr head
    , rqClientIdLen = stringLength $ client head
    , rqClientId = client head
    , rqRequest = packFtRequest
  }
  where
    packFtRequest = FetchRequest
          (-1)
          0
          0
          1
          pts
    pts = map packTopic ts
    packTopic (FromTopic t ps) = RqTopic
          (fromIntegral $ BS.length t)
          t
          (fromIntegral $ length ps)
          (pps ps)
    pps ps = map packPartition ps
    packPartition (FromPart p o) = RqFtPartition
          (fromIntegral p)
          (fromIntegral o)
          1048576 -- Maxbytes

-- | Pack a protocol conform RequestMessage for Metadata API
packMdRqMessage :: Head -> [OfTopic] -> RequestMessage
packMdRqMessage head ts = RequestMessage
  { rqSize = (encodedLength $ buildMetadataRequest $ packMdRequest)
          + 2 -- reqApiKey
          + 2 -- reqApiVersion
          + 4 -- correlationId
          + 2 -- clientIdLen
          + (byteLength $ client head)
    , rqApiKey = 3
    , rqApiVersion = fromIntegral $ apiV head
    , rqCorrelationId = fromIntegral $ corr head
    , rqClientIdLen = stringLength $ client head
    , rqClientId = client head
    , rqRequest = packMdRequest
  }
  where
    packMdRequest = MetadataRequest
          (fromIntegral $ length ts)
          pts
    pts = map packTopic ts
    packTopic (OfTopic t) = RqTopicName
          (fromIntegral $ BC.length t)
          t

--------------------
--Decode Responses Functions
---------------------

-- | Decode response to ResponseMessage of Produce API
decodePrResponse :: BL.ByteString -> ResponseMessage
decodePrResponse a = runGet produceResponseMessageParser a

-- | Decode response to ResponseMessage of Fetch API
decodeFtResponse :: BL.ByteString -> ResponseMessage
decodeFtResponse b = runGet fetchResponseMessageParser b

-- | Decode response to ResponseMessage of Metadata API
decodeMdResponse :: BL.ByteString -> ResponseMessage
decodeMdResponse b = runGet metadataResponseMessageParser b


