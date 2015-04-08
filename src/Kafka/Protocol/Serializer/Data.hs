module Kafka.Protocol.Serializer.Data 
(
buildMessageSet,
buildMessage,
buildPayload
) 
where

import qualified Data.ByteString.Lazy as BL
import Data.Binary.Put
import Kafka.Protocol.Types
import Data.Digest.CRC32


buildMessageSet :: MessageSet -> BL.ByteString
buildMessageSet e = runPut $ do 
  putWord64be $ offset e
  putWord32be $ len e
  putLazyByteString $ buildMessage $ message e

buildMessage :: Message -> BL.ByteString
buildMessage e = runPut $ do 
  --putWord32be $ crc32 $ payloadData $ payload e
  putWord32be $ crc e
  putLazyByteString $ buildPayload $ payload e 

buildPayload :: Payload -> BL.ByteString 
buildPayload e = runPut $ do 
  putWord8    $ magic e
  putWord8    $ attr e
  putWord32be $ keylen $ e
  putWord32be $ payloadLen $ e
  putByteString $ payloadData $ e


