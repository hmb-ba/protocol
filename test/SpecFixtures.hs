module SpecFixtures where

import qualified Data.ByteString.Char8 as BS
import Kafka.Protocol.Types

getMessageSetFixture :: Message -> MessageSet 
getMessageSetFixture m = MessageSet 0 0 m 

getMessageFixture :: Payload -> Message 
getMessageFixture p = Message 0 p 

getPayloadFixture :: [Char] -> Payload 
getPayloadFixture s = Payload 0 0 0 (fromIntegral $ length s) (BS.pack s)

