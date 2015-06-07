{- |
Module      :  Kafka.Protocol.Types
Description :  Types adapted from Apache Kafka Protocol
Copyright   :  (c) Marc Juchli, Lorenz Wolf
License     :
Maintainer  :  mail@marcjuch.li, lorenz.wolf@bluewin.ch
Stability   :  experimental
Portability :  portable

Unsigned integer types adapted from Apache Kafka Protocol. To be used for
encoding/decoding of the request or response messages given from the Kafka API.
-}
module Kafka.Protocol.Types
    ( CorrelationId
    , ClientId
    , NumTopics
    , TopicName
    , PartitionNumber
    , MessageSetSize
    , NumResponses
    , ListLength
    , StringLength
    , Time
    , NumOffset

    , MessageSet (..)
    , Message (..)
    , Payload (..)
    , Offset
    , Crc
    , Magic
    , Attributes
    , Log

    , RequestMessage (..)
    , Request (..)
    , Partition (..)
    , RqTopic (..)
    , RqTopicName (..)

    , Response (..)
    , ResponseMessage (..)
    , RsPayload (..)
    , RsTopic (..)
    , RsMdPartitionMetadata (..)
    ) where

import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import Data.Word

-------------------------------------------------------------------------------
-- Common
-------------------------------------------------------------------------------
type StringLength = Word16
type ListLength = Word32
type BytesLength = Word32

type CorrelationId = Word32
type ClientId = BS.ByteString
type NumTopics = Word32
type TopicName = BS.ByteString
type PartitionNumber = Word32
type MessageSetSize = Word32
type NumResponses = Word32
type Time = Word64
type NumOffset = Word32

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------
type MessageValue  = BS.ByteString
type MessageKey = BS.ByteString
type Offset = Word64
type Crc = Word32
type Magic = Word8
type Attributes = Word8

data Payload = Payload
  { plMagic           :: !Magic
  , plAttr            :: !Attributes
  , plKeylen          :: !BytesLength
  , plKey             :: !MessageKey
  , plValueLen        :: !BytesLength
  , plValue           :: !MessageValue
  } deriving (Show, Eq)

data Message = Message
  { mgCrc             :: !Crc
  , mgPayload         :: !Payload
  } deriving (Show, Eq)

data MessageSet = MessageSet
  { msOffset          :: !Offset
  , msLen             :: !BytesLength
  , msMessage         :: !Message
  } deriving (Show, Eq)

type Log = [MessageSet]


-------------------------------------------------------------------------------
-- Request
-------------------------------------------------------------------------------

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

-- | Request (rq)
data RequestMessage = RequestMessage
  { rqSize               :: !RequestSize
  , rqApiKey             :: !ApiKey
  , rqApiVersion         :: !ApiVersion
  , rqCorrelationId      :: !CorrelationId
  , rqClientIdLen        :: !StringLength
  , rqClientId           :: !ClientId
  , rqRequest            :: Request
  } deriving (Show, Eq)

-- NOTE (meiersi): the field accessors generated from your declaration are all
-- partial functions. You can avoid that by introducing proper records for all
-- the constructors and the create 'Request' such that it just tags these
-- individual types.
data Request = ProduceRequest
  { rqPrRequiredAcks     :: !RequiredAcks
  , rqPrTimeout          :: !Timeout
  , rqPrNumTopics        :: !ListLength
  , rqPrTopics           :: ![RqTopic]
  }
  | MetadataRequest
  { rqMdNumTopics        :: !ListLength
  , rqMdTopicNames       :: ![RqTopicName]
  }
  | FetchRequest
  { rqFtReplicaId        :: !ReplicaId
  , rqFtMaxWaitTime      :: !MaxWaitTime
  , rqFtMinBytes         :: !MinBytes
  , rqFtNumTopics        :: !ListLength
  , rqFtTopics           :: ![RqTopic]
  }
  | OffsetRequest
  { rqOfReplicaId        :: !ReplicaId
  , rqOfNumTopics        :: !ListLength
  , rqOfTopics           :: ![RqTopic]
  }
  | ConsumerMetadataRquest
  { rqCmConsumerGroupLen :: !StringLength
  , rqCmConsumerGroup    :: !ConsumerGroup
  }
  | OffsetCommitRequest
  { rqOcConsumerGroupIdLen :: !StringLength
  , rqOcConsumerGroupId  :: !ConsumerGroupId
  , rqOcConsumerGroupGenerationId :: !ConsumerGroupGenerationId
  , rqOcConsumerId       :: !ConsumerId
  , rqOcRetentionTime    :: !RetentionTime
  , rqOcNumTopics        :: !ListLength
  , rqOcTopic            :: ![RqTopic]
  }
  | OffsetFetchRequest
  { rqOftConsumerGroupLen :: !StringLength
  , rqOftConsumerGroup   :: !ConsumerGroup
  , rqOftNumTopics       :: !ListLength
  , rqOftTopic           :: ![RqTopic]
  }
  deriving (Show, Eq)

data RqTopic = RqTopic
  { rqToNameLen       :: !StringLength
  , rqToName          :: !TopicName
  , rqToNumPartitions :: !ListLength
  , rqToPartitions    :: [Partition]
  } deriving (Show, Eq)

data RqTopicName = RqTopicName
  { rqTnNameLen         :: !StringLength
  , rqTnName            :: !TopicName
  } deriving (Show, Eq)

data Partition =
  -- | ProduceRequest (pr)
  RqPrPartition
  { rqPrPartitionNumber  :: !PartitionNumber
  , rqPrMessageSetSize   :: !MessageSetSize
  , rqPrMessageSet       :: [MessageSet]
  }
  -- | FetchRequest (ft)
  | RqFtPartition
  { rqFtPartitionNumber  :: !PartitionNumber
  , rqFtFetchOffset      :: !Offset
  , rqFtMaxBytes         :: !MaxBytes
  }
  -- | OffsetRequest (of)
  | RqOfPartition
  { rqOfPartitionNumber  :: !PartitionNumber
  , rqOfTime             :: !Time
  , rqOfMaxNumOffset     :: !NumOffset
  }
  -- | OffsetCommitRequest (oc)
  | RqOcPartition
  { rqOcPartitionNumber  :: !PartitionNumber
  , rqOcOffset           :: !Offset
  , rqOcMetadataLen      :: !StringLength
  , rqOcMetadata         :: !Metadata
  }
  -- | OffsetFetchRequest (oft)
  | RqOftPartition
  { rqOftPartitionNumber :: !PartitionNumber
  , rqOftOffset          :: !Offset
  } deriving (Show, Eq)



-------------------------------------------------------------------------------
-- Response
-------------------------------------------------------------------------------

type ErrorCode = Word16
type ErrorCode64 = Word64
type HightwaterMarkOffset = Word64

type RsNodeId = Word32
type RsMdHost = BS.ByteString
type RsMdPort = Word32

type RsOftMetadata = BS.ByteString

-- | Response (Rs)
data ResponseMessage = ResponseMessage
  { rsSize               :: Word32
  , rsCorrelationId      :: !CorrelationId
  , rsResponses          :: !Response
  } deriving (Show)

data Response = ProduceResponse
  { rsPrNumTopic         :: !ListLength
  , rsPrTopic            :: ![RsTopic]
  }
  | MetadataResponse
  { rsMdNumBroker        :: !ListLength
  , rsMdBrokers          :: ![RsPayload]
  , rsMdNumTopicMd       :: !ListLength
  , rsMdTopicMetadata    :: ![RsPayload]
  }
  | FetchResponse
  { rsFtNumTopic         :: !ListLength
  , rsFtTopic            :: ![RsTopic]
  }
  | OffsetResponse
  { rsOfNumTopic         :: !ListLength
  , rsOfTopic            :: !RsTopic
  } deriving (Show)

data RsTopic = RsTopic
  { rsTopicNameLen       :: !StringLength
  , rsTopicName          :: !TopicName
  , rsNumPayloads        :: !ListLength
  , rsPayloads           :: [RsPayload]
  }
  deriving (Show)


data RsPayload =
  -- | Produce Response (Pr)
  RsPrPayload
  { rsPrPartitionNumber  :: !PartitionNumber
  , rsPrCode             :: !ErrorCode
  , rsPrOffset           :: !Offset
  }
  -- | Offset Commit Response (Oc)
  | RsOcPayload
  { rsOcPartitionNumber  :: !PartitionNumber
  , rsOcErrorCode        :: !ErrorCode
  }
  -- | Offset Fetch Response (Oft)
  | RsOftPayload
  { rsOftPartitionNumber :: !PartitionNumber
  , rsOftOffset          :: !Offset
  , rsOftMetadataLen     :: !StringLength
  , rsOftMetadata        :: !RsOftMetadata
  , rsOftErrorCode       :: !ErrorCode
  }
  -- | Fetch Response (Ft)
  | RsFtPayload
  { rsFtPartitionNumber  :: !PartitionNumber
  , rsFtErrorCode        :: !ErrorCode
  , rsFtHwMarkOffset     :: !HightwaterMarkOffset
  , rsFtMessageSetSize   :: !MessageSetSize
  , rsFtMessageSets      :: [MessageSet]
  }
  -- | Metadata Response (Mt)
  | RsMdPayloadBroker
  { rsMdNodeId           :: !RsNodeId
  , rsMdHostLen          :: !StringLength
  , rsMdHost             :: !RsMdHost
  , rsMdPort             :: !RsMdPort
  }
  -- | Metadata Response (Of)
  | RsMdPayloadTopic
  { rsMdTopicErrorCode   :: !ErrorCode
  , rsMdTopicNameLen     :: !StringLength
  , rsMdTopicName        :: !TopicName
  , rsMdNumPartitionMd   :: !ListLength
  , rsMdPartitionMd      :: [RsMdPartitionMetadata]
  }
  -- | Offset Response (Of)
  | RsOfPayload
  { rsOfPartitionNumber  :: !PartitionNumber
  , rsOfErrorCode        :: !ErrorCode64
  , rsOfNumOffsets       :: !ListLength
  , rsOfOffsets          :: [Offset]
  } deriving (Show)

data RsMdPartitionMetadata = RsMdPartitionMetadata
  { rsMdPartitionErrorCode :: !ErrorCode
  , rsMdPartitionId      :: !PartitionNumber
  , rsMdLeader           :: !RsNodeId
  , rsMdNumReplicas      :: !ListLength
  , rsMdReplicas         :: [RsNodeId]
  , rsMdNumIsrs          :: !ListLength
  , rsMdIsrs             :: [RsNodeId]
  } deriving (Show)
