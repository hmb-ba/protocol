module Kafka.Protocol.Types.Request
( RequestMessage (..)
, Request (..)
, Partition (..)
, RqTopic (..)
, RqTopicName (..)
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
type MaxBytes = Word32

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
  } deriving (Show, Eq)

data Request = ProduceRequest
  { rqPrRequiredAcks    :: !RequiredAcks
  , rqPrTimeout         :: !Timeout
  , rqPrNumTopics       :: !ListLength
  , rqPrTopics          :: [RqTopic]
  }
  | MetadataRequest
  { rqMdNumTopics       :: !ListLength
  , rqMdTopicNames      :: [RqTopicName]
  }
  | FetchRequest
  { rqFtReplicaId       :: !ReplicaId
  , rqFtMaxWaitTime     :: !MaxWaitTime
  , rqFtMinBytes        :: !MinBytes
  , rqFtNumTopics       :: !ListLength
  , rqFtTopics          :: ![RqTopic]
  }
  | OffsetRequest
  { rqOfReplicaId       :: !ReplicaId
  , rqOfNumTopics       :: !ListLength
  , rqOfTopics          :: ![RqTopic]
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
  , rqOcTopic                       :: [RqTopic]
  }
  | OffsetFetchRequest
  { rqOftConsumerGroupLen           :: !StringLength
  , rqOftConsumerGroup              :: !ConsumerGroup
  , rqOftNumTopics                  :: !ListLength
  , rqOftTopic                      :: [RqTopic]
  }
  deriving (Show, Eq)

data RqTopic = RqTopic
  { rqTopicNameLen    :: !StringLength
  , rqTopicName       :: !TopicName
  , numPartitions   :: !ListLength
  , partitions      :: [Partition]
  } deriving (Show, Eq)

data RqTopicName = RqTopicName
  { topicNameLen    :: !StringLength
  , topicName       :: !TopicName
  } deriving (Show, Eq)

data Partition =
  ----------------------
  -- ProduceRequest (pr)
  ----------------------
  RqPrPartition
  { rqPrPartitionNumber :: !PartitionNumber
  , rqPrMessageSetSize  :: !MessageSetSize
  , rqPrMessageSet      :: [MessageSet]
  }
  |
  ----------------------
  -- FetchRequest (ft)
  ----------------------
  RqFtPartition
  { rqFtPartitionNumber :: !PartitionNumber
  , rqFtFetchOffset     :: !Offset
  , rqFtMaxBytes        :: !MaxBytes
  }
  |
  ----------------------
  -- OffsetRequest (of)
  ----------------------
  RqOfPartition
  { rqOfPartitionNumber :: !PartitionNumber
  , rqOfTime            :: !Time
  , rqOfMaxNumOffset    :: !NumOffset
  }
  |
  ---------------------------
  -- OffsetCommitRequest (oc)
  ---------------------------
  RqOcPartition
  { rqOcPartitionNumber :: !PartitionNumber
  , rqOcOffset          :: !Offset
  , rqOcMetadataLen     :: !StringLength
  , rqOcMetadata        :: !Metadata
  }
  |
  ---------------------------
  -- OffsetFetchRequest (oft)
  ---------------------------
  RqOftPartition
  { rqOftPartitionNumber :: !PartitionNumber
  , rqOftOffset          :: !Offset
  } deriving (Show, Eq)

