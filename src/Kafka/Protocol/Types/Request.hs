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


data RequestMessage = RequestMessage
  { rqSize     :: !RequestSize
  , rqApiKey          :: !ApiKey
  , rqApiVersion      :: !ApiVersion
  , rqCorrelationId   :: !CorrelationId
  , rqClientIdLen     :: !ClientIdLen
  , rqClientId        :: !ClientId
  , rqRequest            :: Request
  } deriving (Show)

data Request = ProduceRequest
  { rqPrRequiredAcks    :: !RequiredAcks
  , rqPrTimeout         :: !Timeout
  , rqPrNumTopics       :: !NumTopics
  , rqPrTopics          :: [Topic]
  }
  | MetadataRequest
  { rqMdTopicNames      :: [TopicName] }
  | FetchRequest
  { rqMdReplicaId       :: !ReplicaId
  , rqMdMaxWaitTime     :: !MaxWaitTime
  , rqMdMinBytes        :: !MinBytes
  }
  deriving (Show)

data RqPrTopic = RqPrTopic
  { rqPrTopicNameLen    :: !TopicNameLen
  , rqPrTopicName       :: !TopicName
  , rqPrNumPartitions   :: !NumPartitions
  , rqPrPartitions      :: [Partition]
  } deriving (Show)

data RqPrPartition = RqPrPartition
  { rqPrPartitionNumber :: !PartitionNumber
  , rqPrMessageSetSize  :: !MessageSetSize
  , rqPrMessageSet      :: [MessageSet]
  } deriving (Show)


