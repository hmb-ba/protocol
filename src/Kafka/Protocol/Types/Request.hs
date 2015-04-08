module Kafka.Protocol.Types.Request
( RequestMessage (..)
, RequestSize
, ApiKey
, ApiVersion
, CorrelationId
, ClientId
, Request (..)
, RequiredAcks
, Timeout
, NumTopics
, Topic (..)
, TopicName
, TopicNameLen
, NumPartitions
, Partition (..)
, PartitionNumber
) where

import Data.Word
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import Kafka.Protocol.Types.Message
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


data RequestMessage = RequestMessage
  { reqSize     :: !RequestSize
  , reqApiKey          :: !ApiKey
  , reqApiVersion      :: !ApiVersion
  , reqCorrelationId   :: !CorrelationId
  , reqClientIdLen     :: !ClientIdLen
  , reqClientId        :: !ClientId
  , request            :: Request
  } deriving (Show)

data Request = ProduceRequest
  { reqRequiredAcks    :: !RequiredAcks
  , reqTimeout         :: !Timeout
  , reqNumTopics       :: !NumTopics
  , reqTopics          :: [Topic]
  }
  | MetadataRequest
  { reqTopicNames      :: [TopicName] }
  | FetchRequest
  { fetReplicaId       :: !ReplicaId
  , fetMaxWaitTime     :: !MaxWaitTime
  , fetMinBytes        :: !MinBytes
  }
  deriving (Show)

data Topic = Topic
  { topicNameLen    :: !TopicNameLen
  , topicName       :: !TopicName
  , numPartitions   :: !NumPartitions
  , partitions      :: [Partition]
  } deriving (Show)

data Partition = Partition
  { partitionNumber :: !PartitionNumber
  , messageSetSize  :: !MessageSetSize
  , messageSet      :: [MessageSet]
  } deriving (Show)


