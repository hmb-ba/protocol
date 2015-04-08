module Kafka.Protocol.Parser.Data
(messageSetParser )
where 

import Kafka.Protocol.Types
import Data.Binary.Get
import qualified Data.ByteString.Lazy as BL

payloadParser :: Get Payload
payloadParser = do
  magic  <- getWord8
  attr   <- getWord8
  keylen <- getWord32be
  paylen <- getWord32be
  payload <- getByteString $ fromIntegral paylen
  return $! Payload magic attr keylen paylen payload

messageParser :: Get Message 
messageParser = do 
  crc    <- getWord32be
  p      <- payloadParser
  return $! Message crc p

messageSetParser :: Get MessageSet 
messageSetParser = do 
  offset <- getWord64be
  len <- getWord32be 
  message <- messageParser
  return $! MessageSet offset len message

