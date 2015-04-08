module Kafka.Protocol.Types.Response
( Response (..)
, ResponseMessage (..)
, Error (..)
) where

import Data.Word
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import Kafka.Protocol.Types.Message
import Kafka.Protocol.Types.Common

type ErrorCode = Word16
type NumErrors = Word32
type HightwaterMarkOffset = Word64
type ListLength = Word32

data ResponseMessage = ResponseMessage
  { resCorrelationId   :: !CorrelationId
  , resNumResponses    :: !NumResponses
  , responses        :: [Response]
  } deriving (Show)

data Response = ProduceResponse
  { resTopicNameLen    :: !TopicNameLen
  , resTopicName       :: !TopicName 
  , resNumErrors       :: !NumErrors
  , resErrors          :: [Error]
  }
  | MetadataResponse 
  { resTopicNameLen    :: !TopicNameLen
  , resTopicName       :: !TopicName 
  }
  | FetchResponse 
  { fetNumFetchs       :: !ListLength
  , fetFetchs          :: [Fetch]
  } deriving (Show) 


data Error = Error 
  { errPartitionNumber :: !PartitionNumber
  , errCode       :: !ErrorCode
  , errOffset          :: !Offset
  } deriving (Show)

data Fetch = Fetch
  { fetTopicNameLen     :: !TopicNameLen
  , fetNumsPayloads     :: !ListLength
  , fetPayloads         :: [FetResPayload]
  } deriving (Show) 

data FetResPayload = FetResPayload 
  { fetPartitionNumber  :: !PartitionNumber
  , fetErrorCode        :: !ErrorCode 
  , fetHighwaterMarkOffset :: !HightwaterMarkOffset
  , fetMessageSetSize   :: !MessageSetSize
  , fetMessageSet       :: !MessageSet 
  } deriving (Show)

