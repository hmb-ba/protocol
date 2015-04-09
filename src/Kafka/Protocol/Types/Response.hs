module Kafka.Protocol.Types.Response
( Response (..)
, ResponseMessage (..)
, RsPrError (..)
, RsFtPayload (..)
) where

import Data.Word
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import Kafka.Protocol.Types.Data
import Kafka.Protocol.Types.Common

type ErrorCode = Word16
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
  { rsPrTopicNameLen    :: !StringLength
  , rsPrTopicName       :: !TopicName
  , rsPrNumErrors       :: !ListLength
  , rsPrErrors          :: [RsPrError]
  }
  | MetadataResponse
  { rsMdNumBroker       :: !ListLength
  , rsMdBrokers         :: ![RsMdBroker]
  , rsMdNumTopicMd      :: !ListLength
  , rsMdTopicMetadata   :: ![RsMdTopicMetadata]
  }
  | FetchResponse
  { rsFtTopicNameLen     :: !StringLength
  , rsFtTopicName        :: !TopicName
  , rsFtNumsPayloads     :: !ListLength
  , rsFtPayloads         :: [RsFtPayload]
  }
  | OffsetResponse
  { rsOfTopicNameLen    :: !StringLength
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
  { rsOcTopicNameLen    :: !StringLength
  , rsOcTopicName       :: !TopicName
  , rsOcNumErrors       :: !ListLength
  , rsOcErrors          :: [RsOcError]
  } 
  | OffsetFetchResponse
  { rsOftTopicNameLen   :: !StringLength
  , rsOftTopicName      :: !TopicName
  , rsOftNumErrors      :: !ListLength
  , rsOftErrors         :: [RsOftError]
  } deriving (Show)

--------------------
-- Produce Response (Pr)
--------------------
data RsPrError = RsPrError
  { rsPrPartitionNumber :: !PartitionNumber
  , rsPrCode            :: !ErrorCode
  , rsPrOffset          :: !Offset
  } deriving (Show)

--------------------
-- Metadata Response (Mt)
--------------------
data RsMdBroker = RsMdBroker
  { rsMdNodeId          :: !RsNodeId
  , rsMdHost            :: !RsMdHost
  , rsMdPort            :: !RsMdPort
  } deriving (Show)

data RsMdTopicMetadata = RsMdTopicMetadata
  { rsMdTopicErrorCode  :: !ErrorCode
  , rsMdTopicNameLen    :: !StringLength
  , rsMdTopicName       :: !TopicName
  , rsMdNumPartitionMd  :: !ListLength
  , rsMdPartitionMd     :: [RsMdPartitionMetadata]
  } deriving (Show)

data RsMdPartitionMetadata = RsMdPartitionMetadata
  { rsMdPartitionErrorCode :: !ErrorCode
  , rsMdPartitionId        :: !PartitionNumber
  , rsMdLeader             :: !RsNodeId
  , rsMdReplicas           :: [RsNodeId]
  , rsMdIsr                :: [RsNodeId]
  } deriving (Show)

-------------------
-- Fetch Response (Ft)
-------------------
data RsFtPayload = RsFtPayload
  { rsFtPartitionNumber  :: !PartitionNumber
  , rsFtErrorCode        :: !ErrorCode
  , rsFtHwMarkOffset     :: !HightwaterMarkOffset
  , rsFtMessageSetSize   :: !MessageSetSize
  , rsFtMessageSet       :: !MessageSet
  } deriving (Show)

-------------------
-- Offset Response (Of)
-------------------
data RsOfPartitionOf = RsOfPartitionOf
  { rsOfPartitionNumber :: !PartitionNumber
  , rsOfErrorCode       :: !ErrorCode
  , rsOfOffset          :: !Offset
  } deriving (Show)

-------------------
-- Offset Commit Response (Oc)
-------------------
data RsOcError = RsOcError
  { rsOcPartitionNumber :: !PartitionNumber
  , rsOcErrorCode       :: !ErrorCode
  } deriving (Show)

-------------------
-- Offset Fetch Response (Oft)
-------------------
data RsOftError = RsOftError
  { rsOftPartitionNumber  :: !PartitionNumber
  , rsOftOffset           :: !Offset
  , rsOftMetadataLen      :: !StringLength
  , rsOftMetadata         :: !RsOftMetadata
  , rsOftErrorCode        :: !ErrorCode
  } deriving (Show)

