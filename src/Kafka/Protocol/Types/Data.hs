module Kafka.Protocol.Types.Data
( MessageSet (..)
, Message (..)
, Payload (..)
, PayloadData
, Offset
, Length
, Crc
, Magic
, Attributes
, KeyLength
, PayloadLength
, Log
) where

import Data.Word
import qualified Data.ByteString as BS

type PayloadData = BS.ByteString
type Offset = Word64
type Length = Word32
type Crc = Word32
type Magic = Word8
type Attributes = Word8
type KeyLength = Word32
type PayloadLength = Word32

data Payload = Payload
  { magic   :: !Magic
  , attr    :: !Attributes
  , keylen      :: !KeyLength
  --todo: key
  , payloadLen  :: !PayloadLength
  , payloadData :: !PayloadData
  } deriving (Show, Eq)

data Message = Message 
  { crc     :: !Crc
  , payload :: Payload
  } deriving (Show, Eq)

data MessageSet = MessageSet
  { offset  :: !Offset
  , len     :: !Length
  , message :: !Message 
  } deriving (Show, Eq)

----------------------
-- Types used for Log
----------------------
type Log = [MessageSet]


