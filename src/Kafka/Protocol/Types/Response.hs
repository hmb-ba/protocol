module Kafka.Protocol.Types.Response
( Response (..)
, ResponseMessage (..)
, RsPrError (..)
) where

import Data.Word
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import Kafka.Protocol.Types.Data
import Kafka.Protocol.Types.Common

type RsErrorCode = Word16
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
  , rsReponses        :: [Response]
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
  { rsFtNumFetchs       :: !ListLength
  , rsFtFetchs          :: [RsFtFetch]
  }
  | OffsetResponse
  { rsOfNumOffsets      :: !ListLength
  , rsOfOffsets         :: [RsOfOffset]
  }
  | ConsumerMetadataResponse
  { rsCmErrorCode       :: !RsErrorCode
  , rsCmCoordinatorId   :: !RsNodeId
  , rsCmCoordinatorIdLen :: !StringLength
  , rsCmCoordinatorPort :: !RsMdPort
  }
  | OffsetCommitResponse
  { rsOcNumCommits    :: !ListLength
  , rsOcCommits       :: [RsOcCommit]
  }
  | OffsetFetchResponse
  { rsOftNumFetch     :: !ListLength
  , rsOftFetchs       :: [RsOftFetch]
  } deriving (Show)

--------------------
-- Produce Response (Pr)
--------------------
data RsPrError = RsPrError
  { rsPrPartitionNumber :: !PartitionNumber
  , rsPrCode            :: !RsErrorCode
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

data RsMtTopicMetadata = RsMtTopicMetadata
  { rsMdTopicErrorCode  :: !RsErrorCode
  , rsMdTopicNameLen    :: !StringLength
  , rsMdTopicName       :: !TopicName
  , rsMdNumPartitionMd  :: !ListLength
  , rsMdPartitionMd     :: [RsMdPartitionMetadata]
  } deriving (Show)

data RsMdPartitionMetadata = RsMdPartitionMetadata
  { rsMdPartitionErrorCode :: !RsErrorCode
  , rsMdPartitionId        :: !PartitionNumber
  , rsMdLeader             :: !RsNodeId
  , rsMdReplicas           :: [RsNodeId]
  , rsMdIsr                :: [RsNodeId]
  } deriving (Show)

-------------------
-- Fetch Response (Ft)
-------------------
data RsFtFetch = RsFtFetch
  { rsFtTopicNameLen     :: !StringLength
  , rsFtTopicName        :: !TopicName
  , rsFtNumsPayloads     :: !ListLength
  , rsFtPayloads         :: [RsFtPayload]
  } deriving (Show)

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
data  RsOfOffset = RsOfOffset
  { rsOfTopicNameLen    :: !StringLength
  , rsOfTopicName       :: !TopicName
  , rsOfNumPartitionOfs :: !ListLength
  } deriving (Show)

data RsOfPartitionsOf = RsOfPartitionOf
  { rsOfPartitionNumber :: !PartitionNumber
  , rsOfErrorCode       :: !RsErrorCode
  , rsOfOffset          :: !Offset
  } deriving (Show)

-------------------
-- Offset Commit Response (Oc)
-------------------
data RsOcCommit = RcOcCommit
  { rsOcTopicNameLen    :: !StringLength
  , rsOcTopicName       :: !TopicName
  , rsOcNumErrors       :: !ListLength
  , rsOcErrors          :: [RsOcError]
  }

data RsOcError = RsOcError
  { rsOcPartitionNumber :: !PartitionNumber
  , rsOcErrorCode       :: !RsErrorCode
  }

-------------------
-- Offset Fetch Response (Oft)
-------------------
data RsOftFetch = RsOftFetch
  { rsOftTopicNameLen   :: !StringLength
  , rsOftTopicName      :: !TopicName
  , rsOftNumErrors      :: !ListLength
  , rsOftErrors         :: [RsOftError]
  }

data RsOftError = RsOftError
{ rsOftPartitionNumber  :: !PartitionNumber
, rsOftOffset           :: !Offset
, rsOftMetadataLen      :: !StringLength
, rsOftMetadata         :: !RsOftMetadata
, rsOftErrorCode        :: !RsErrorCode
}
