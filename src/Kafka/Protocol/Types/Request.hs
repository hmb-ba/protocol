module Kafka.Protocol.Types.Request
( RequestMessage (..)
, Request (..)
, RqPrPartition (..)
, RqPrTopic (..)
)
 where

import Data.Word
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import Kafka.Protocol.Types.Data
import Kafka.Protocol.Types.Common

type RequestSize = Word32
type ApiKey = Word16
type ApiVersion = Word16
type RequiredAcks = Word16
type Timeout = Word32
type NumPartitions = Word32

type ReplicaId = Word32
type MaxWaitTime = Word32
type MinBytes = Word32

type ConsumerGroup = BS.ByteString
type ConsumerGroupId = BS.ByteString
type ConsumerGroupGenerationId = Word32
type ConsumerId = BS.ByteString
type RetentionTime = Word64
type Metadata = BS.ByteString

---------------
-- Request (rq)
---------------

data RequestMessage = RequestMessage
  { rqSize            :: !RequestSize
  , rqApiKey          :: !ApiKey
  , rqApiVersion      :: !ApiVersion
  , rqCorrelationId   :: !CorrelationId
  , rqClientIdLen     :: !ClientIdLen
  , rqClientId        :: !ClientId
  , rqRequest         :: Request
  } deriving (Show)

data Request = ProduceRequest
  { rqPrRequiredAcks    :: !RequiredAcks
  , rqPrTimeout         :: !Timeout
  , rqPrNumTopics       :: !ListLength
  , rqPrTopics          :: [RqPrTopic]
  }
  | MetadataRequest
  { rqMdTopicNames      :: [TopicName] }
  | FetchRequest
  { rqFtReplicaId       :: !ReplicaId
  , rqFtMaxWaitTime     :: !MaxWaitTime
  , rqFtMinBytes        :: !MinBytes
  , rqFtNumTopics       :: !ListLength
  , rqFtTopics          :: ![RqFtTopic]
  }
  | OffsetRequest
  { rqOfReplicaId       :: !ReplicaId
  , rqOfNumTopics       :: !ListLength
  , rqOfTopics          :: ![RqOfTopic]
  }
  | ConsumerMetadataRquest
  { rqCmConsumerGroupLen   :: !StringLength
  , rqCmConsumerGroup      :: !ConsumerGroup
  }
  | OffsetCommitRequest 
  { rqOcConsumerGroupIdLen          :: !StringLength
  , rqOcConsumerGroupId             :: !ConsumerGroupId
  , rqOcConsumerGroupGenerationId   :: !ConsumerGroupGenerationId
  , rqOcConsumerId                  :: !ConsumerId
  , rqOcRetentionTime               :: !RetentionTime
  , rqOcNumTopics                   :: !ListLength
  , rqOcTopic                       :: [RqOcTopic]
  }
  | OffsetFetchRequest
  { rqOftConsumerGroupLen           :: !StringLength
  , rqOftConsumerGroup              :: !ConsumerGroup
  , rqOftNumTopics                  :: !ListLength
  , rqOftTopic                      :: [RqOftTopic]
  }
  deriving (Show)

----------------------
-- ProduceRequest (pr)
----------------------

data RqPrTopic = RqPrTopic
  { rqPrTopicNameLen    :: !StringLength
  , rqPrTopicName       :: !TopicName
  , rqPrNumPartitions   :: !ListLength
  , rqPrPartitions      :: [RqPrPartition]
  } deriving (Show)

data RqPrPartition = RqPrPartition
  { rqPrPartitionNumber :: !PartitionNumber
  , rqPrMessageSetSize  :: !MessageSetSize
  , rqPrMessageSet      :: [MessageSet]
  } deriving (Show)

----------------------
-- FetchRequest (ft)
----------------------

data RqFtTopic = RqFtTopic
  { rqFtTopicNameLen    :: !StringLength
  , rqFtTopicName       :: !TopicName
  , rqFtNumPartitions   :: !ListLength
  , rqFtPartitions      :: [RqFtPartition]
  } deriving (Show)

data RqFtPartition = RqFtPartition
  { rqFtPartitionNumber :: !PartitionNumber
  , rqFtFetchOffset     :: !ByteLength
  , rqFtMaxBytes        :: !ByteLength
  } deriving (Show)

----------------------
-- OffsetRequest (of)
----------------------

data RqOfTopic = RqOfTopic
  { rqOfTopicNameLen    :: !StringLength
  , rqOfTopicName       :: !TopicName
  , rqOfNumPartitions   :: !ListLength
  , rqOfPartitions      :: [RqFtPartition]
  } deriving (Show)

data RqOfPartition = RqOfPartition
  { rqOfPartitionNumber :: !PartitionNumber
  , rqOfTime            :: !Time
  , rqOfMaxNumOffset    :: !NumOffset
  } deriving (Show)

---------------------------
-- OffsetCommitRequest (oc)
---------------------------

data RqOcTopic = RqOcTopic
  { rqOcTopicNameLen    :: !StringLength
  , rqOcTopicName       :: !TopicName
  , rqOcNumPartitions   :: !ListLength
  , rqOcPartitions      :: [RqOcPartition]
  } deriving (Show)

data RqOcPartition = RqOcPartition
  { rqOcPartitionNumber :: !PartitionNumber
  , rqOcOffset          :: !Offset
  , rqOcMetadataLen     :: !StringLength
  , rqOcMetadata        :: !Metadata
  } deriving (Show)

---------------------------
-- OffsetFetchRequest (oft)
---------------------------

data RqOftTopic = RqOftTopic
  { rqOftTopicNameLen    :: !StringLength
  , rqOftTopicName       :: !TopicName
  , rqOftNumPartitions   :: !ListLength
  , rqOftPartitions      :: [RqOftPartition]
  } deriving (Show)

data RqOftPartition = RqOftPartition
  { rqOftPartitionNumber :: !PartitionNumber
  , rqOftOffset          :: !Offset
  } deriving (Show)

