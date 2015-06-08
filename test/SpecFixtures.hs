module SpecFixtures where

import Data.Binary.Put
import qualified Data.ByteString.Lazy.Char8 as BL
import qualified Data.ByteString.Char8 as BS
import Data.Word

import Kafka.Protocol

getMessageSetFixture :: Message -> MessageSet
getMessageSetFixture m = MessageSet
  { msOffset        = 0
  , msLen           = encodedLength $ buildMessage m
  , msMessage       = m
  }

getMessageFixture :: Payload -> Message
getMessageFixture p = Message
  { mgCrc           = 0
  , mgPayload       = p
  }

getPayloadFixture :: [Char] -> Payload
getPayloadFixture s = Payload
  { plMagic         = 0
  , plAttr          = 0
  , plKey           = 0
  , plValueLen      = (fromIntegral $ length s)
  , plValue         = (BS.pack s)
  }

getRequestMessageFixture :: Request -> RequestMessage
getRequestMessageFixture r = RequestMessage
  { rqSize          = (encodedLength $ buildProduceRequest r)
          + 2 -- reqApiKey
          + 2 -- reqApiVersion
          + 4 -- correlationId
          + 2 -- clientIdLen
          + (fromIntegral $ length "ClientId") --clientId
  , rqApiKey        = 0
  , rqApiVersion    = 0
  , rqCorrelationId = 0
  , rqClientIdLen   = (fromIntegral $ length "ClientId")
  , rqClientId      = (BS.pack "ClientId")
  , rqRequest       = r
  }

getProduceRequestFixture :: [RqTopic] -> Request
getProduceRequestFixture ts = ProduceRequest
  { rqPrRequiredAcks = 0
  , rqPrTimeout      = 0
  , rqPrNumTopics    = (fromIntegral $ length ts)
  , rqPrTopics       = ts
  }

getTopicFixture :: [Char] -> [Partition] -> RqTopic
getTopicFixture s ps = RqTopic
  { rqToNameLen     = (fromIntegral $ length s)
  , rqToName        = (BS.pack s)
  , rqToNumPartitions    = (fromIntegral $ length ps)
  , rqToPartitions       = ps
  }

getRqPrPartitionFixture :: [MessageSet] -> Partition
getRqPrPartitionFixture ms = RqPrPartition
  { rqPrPartitionNumber  = 0
  , rqPrMessageSetSize   =  encodedLength $ buildMessageSets ms
  , rqPrMessageSet       = ms
  }

encodedLength :: Put -> Word32
encodedLength p = fromIntegral $ BL.length $ runPut p



