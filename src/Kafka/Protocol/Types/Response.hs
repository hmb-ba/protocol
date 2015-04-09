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

type RsMdNodeId = Word32
type RsMdHost = BS.ByteString
type RsMdPort = Word32

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
  } deriving (Show)
  | OffsetResponse
  {
    rsOfNumOffsets      ::!ListLength
  , rsOfOffsets         ::[RsOfOffset]
  }

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
  { rsMdNodeId          :: !RsMdNodeId
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
  , rsMdLeader             :: !RsMdNodeId
  , rsMdReplicas           :: [RsMdNodeId]
  , rsMdIsr                :: [RsMdNodeId]
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
