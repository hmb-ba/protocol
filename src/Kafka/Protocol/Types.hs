module Kafka.Protocol.Types
( CorrelationId
, ClientId
, ClientIdLen
, NumTopics
, TopicName
, PartitionNumber
, MessageSetSize
, NumResponses
, ListLength
, ByteLength
, StringLength
, Time
, NumOffset

, MessageSet (..)
, Message (..)
, Payload (..)
, PayloadData
, Offset
, Length
, Crc
, Magic
, Attributes
, KeyLength
, PayloadLength
, Log

, RequestMessage (..)
, Request (..)
, Partition (..)
, RqTopic (..)
, RqTopicName (..)

, Response (..)
, ResponseMessage (..)
, RsPayload (..)
, RsOfPartitionOf (..)
, RsTopic (..)
, RsMdPartitionMetadata (..)
) where


import Data.Word
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL

--------------------------------------------------------
-- Common
--------------------------------------------------------

type ListLength = Word32
type StringLength = Word16
type ByteLength = Word32
type CorrelationId = Word32
type ClientId = BS.ByteString
type ClientIdLen = Word16
type NumTopics = Word32
type TopicName = BS.ByteString
type PartitionNumber = Word32
type MessageSetSize = Word32
type NumResponses = Word32
type Time = Word64
type NumOffset = Word32


--------------------------------------------------------
-- Data
--------------------------------------------------------

type PayloadData = BS.ByteString
type Offset = Word64
type Length = Word32
type Crc = Word32
type Magic = Word8
type Attributes = Word8
type KeyLength = Word32
type PayloadLength = Word32

data Payload = Payload
  { magic   :: !Magic
  , attr    :: !Attributes
  , keylen      :: !KeyLength
  --todo: key
  , payloadLen  :: !PayloadLength
  , payloadData :: !PayloadData
  } deriving (Show, Eq)

data Message = Message 
  { crc     :: !Crc
  , payload :: Payload
  } deriving (Show, Eq)

data MessageSet = MessageSet
  { offset  :: !Offset
  , len     :: !Length
  , message :: !Message 
  } deriving (Show, Eq)

----------------------
-- Types used for Log
----------------------
type Log = [MessageSet]



--------------------------------------------------------
-- Request
--------------------------------------------------------


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



--------------------------------------------------------
-- Response
--------------------------------------------------------


type ErrorCode = Word16
type ErrorCode64 = Word64
type HightwaterMarkOffset = Word64

type RsNodeId = Word32
type RsMdHost = BS.ByteString
type RsMdPort = Word32

type RsOftMetadata = BS.ByteString

--------------------
-- Response (Rs)
--------------------
data ResponseMessage = ResponseMessage
  { rsCorrelationId   :: !CorrelationId
  , rsNumResponses    :: !ListLength
  , rsResponses        :: [Response]
  } deriving (Show)

data Response = ProduceResponse
  {
    rsPrTopic          :: !RsTopic
  }
  | MetadataResponse
  { rsMdNumBroker       :: !ListLength
  , rsMdBrokers         :: ![RsPayload]
  , rsMdNumTopicMd      :: !ListLength
  , rsMdTopicMetadata   :: ![RsPayload]
  }
  | FetchResponse
  { rsFtTopicNameLen     :: !StringLength
  , rsFtTopicName        :: !TopicName
  , rsFtNumsPayloads     :: !ListLength
  , rsFtPayloads         :: [RsPayload]
  }
  | OffsetResponse
  { rsOfTopicNameLen    ::  !StringLength
  , rsOfTopicName        :: !TopicName
  , rsOfNumPartitionOfs  :: !ListLength
  , rsOfPartitionOfs     :: [RsOfPartitionOf]
  }
  | ConsumerMetadataResponse
  { rsCmErrorCode       :: !ErrorCode
  , rsCmCoordinatorId   :: !RsNodeId
  , rsCmCoordinatorIdLen :: !StringLength
  , rsCmCoordinatorPort :: !RsMdPort
  }
  | OffsetCommitResponse
  {
    sOcTopic           :: !RsTopic 
  }
  | OffsetFetchResponse
  {
    rsPrTopic           :: !RsTopic
  } deriving (Show)

data RsTopic = RsTopic 
  { rsTopicNameLen        :: !StringLength
  , rsTopicName           :: !TopicName 
  , rsNumPayloads         :: !ListLength 
  , rsPayloads            :: [RsPayload]
  } deriving (Show)


data RsPayload =
  -------------------
  -- Produce Response (Pr)
  --------------------
  RsPrPayload
  { rsPrPartitionNumber :: !PartitionNumber
  , rsPrCode            :: !ErrorCode
  , rsPrOffset          :: !Offset
  }
  |
  -------------------
  -- Offset Commit Response (Oc)
  -------------------
  RsOcPayload
  { rsOcPartitionNumber :: !PartitionNumber
  , rsOcErrorCode       :: !ErrorCode
  }
  |
  -------------------
  -- Offset Fetch Response (Oft)
  -------------------
  RsOftPayload
  { rsOftPartitionNumber  :: !PartitionNumber
  , rsOftOffset           :: !Offset
  , rsOftMetadataLen      :: !StringLength
  , rsOftMetadata         :: !RsOftMetadata
  , rsOftErrorCode        :: !ErrorCode
  }
  |
  -------------------
  -- Fetch Response (Ft)
  -------------------
  RsFtPayload
  { rsFtPartitionNumber  :: !PartitionNumber
  , rsFtErrorCode        :: !ErrorCode
  , rsFtHwMarkOffset     :: !HightwaterMarkOffset
  , rsFtMessageSetSize   :: !MessageSetSize
  , rsFtMessageSets      :: [MessageSet]
  } 
  |
  --------------------
  -- Metadata Response (Mt)
  --------------------
  RsMdPayloadBroker
  { rsMdNodeId          :: !RsNodeId
  , rsMdHostLen         :: !StringLength
  , rsMdHost            :: !RsMdHost
  , rsMdPort            :: !RsMdPort
  }
  |
  RsMdPayloadTopic
  { rsMdTopicErrorCode  :: !ErrorCode
  , rsMdTopicNameLen    :: !StringLength
  , rsMdTopicName       :: !TopicName
  , rsMdNumPartitionMd  :: !ListLength
  , rsMdPartitionMd     :: [RsMdPartitionMetadata]
  }
  deriving (Show)

data RsMdPartitionMetadata = RsMdPartitionMetadata
  { rsMdPartitionErrorCode :: !ErrorCode
  , rsMdPartitionId        :: !PartitionNumber
  , rsMdLeader             :: !RsNodeId
  , rsMdNumReplicas        :: !ListLength
  , rsMdReplicas           :: [RsNodeId]
  , rsMdNumIsrs            :: !ListLength
  , rsMdIsrs                :: [RsNodeId]
  } deriving (Show)

-------------------
-- Offset Response (Of)
-------------------
data RsOfPartitionOf = RsOfPartitionOf
  { rsOfPartitionNumber :: !PartitionNumber
  , rsOfErrorCode       :: !ErrorCode64
  , rsOfNumOffsets      :: !ListLength
  , rsOfOffsets          :: [Offset]
  } deriving (Show)



