module SpecFixtures where

import qualified Data.ByteString.Lazy.Char8 as BL
import qualified Data.ByteString.Char8 as BS
import Kafka.Protocol

import Data.Binary.Put

getMessageSetFixture :: Message -> MessageSet
getMessageSetFixture m = MessageSet 0 0 m

getMessageFixture :: Payload -> Message
getMessageFixture p = Message 0 p

getPayloadFixture :: [Char] -> Payload
-- FIXME (meiersi): for a reader this line is really quite magical with all
-- the similar positional arguments. Consider constructing the record with
-- named arguemnts to make your code change-proof, and make your code more
-- readable.
getPayloadFixture s = Payload 0 0 0 (fromIntegral $ length s) (BS.pack s)

getRequestMessageFixture :: Request -> RequestMessage
getRequestMessageFixture r = RequestMessage 1000 0 0 1 (fromIntegral $ length "ClientId") (BS.pack "ClientId") r

getProduceRequestFixture :: [RqTopic] -> Request
getProduceRequestFixture ts = ProduceRequest 0 0 (fromIntegral $ length ts) ts

getTopicFixture :: [Char] -> [Partition] -> RqTopic
getTopicFixture s ps = RqTopic (fromIntegral $ length s) (BS.pack s) (fromIntegral $ length ps) ps

getRqPrPartitionFixture :: [MessageSet] -> Partition
getRqPrPartitionFixture ms = RqPrPartition 0 (fromIntegral $ BL.length $ runPut $ buildMessageSets ms ) ms


