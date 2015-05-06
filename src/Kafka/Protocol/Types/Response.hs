module Kafka.Protocol.Types.Response
( Response (..)
, ResponseMessage (..)
, RsPayload (..)
, RsOfPartitionOf (..)
, RsTopic (..)
, RsMdPartitionMetadata (..)
) where

import Data.Word
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import Kafka.Protocol.Types.Data
import Kafka.Protocol.Types.Common

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


