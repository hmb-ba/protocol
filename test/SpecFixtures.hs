module SpecFixtures where

import qualified Data.ByteString.Lazy.Char8 as BL
import qualified Data.ByteString.Char8 as BS
import Kafka.Protocol

getMessageSetFixture :: Message -> MessageSet
getMessageSetFixture m = MessageSet 0 0 m

getMessageFixture :: Payload -> Message
getMessageFixture p = Message 0 p

getPayloadFixture :: [Char] -> Payload
getPayloadFixture s = Payload 0 0 0 (fromIntegral $ length s) (BS.pack s)

getRequestMessageFixture :: Request -> RequestMessage
getRequestMessageFixture r = RequestMessage 1000 0 0 1 (fromIntegral $ length "ClientId") (BS.pack "ClientId") r

getProduceRequestFixture :: [RqTopic] -> Request
getProduceRequestFixture ts = ProduceRequest 0 0 (fromIntegral $ length ts) ts

getTopicFixture :: [Char] -> [Partition] -> RqTopic
getTopicFixture s ps = RqTopic (fromIntegral $ length s) (BS.pack s) (fromIntegral $ length ps) ps

getRqPrPartitionFixture :: [MessageSet] -> Partition
getRqPrPartitionFixture ms = RqPrPartition 0 (fromIntegral $ BL.length $ buildMessageSets ms ) ms


