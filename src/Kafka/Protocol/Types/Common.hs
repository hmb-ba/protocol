module Kafka.Protocol.Types.Common
( CorrelationId
, ClientId
, ClientIdLen
, NumTopics
, TopicName
, TopicNameLen
, PartitionNumber
, MessageSetSize
, NumResponses
, ListLength
, ByteLength
) where

import Data.Word
import qualified Data.ByteString as BS

type ListLength = Word32
type StringLength = Word16
type ByteLength = Word32

type CorrelationId = Word32
type ClientId = BS.ByteString
type ClientIdLen = Word16
type NumTopics = Word32
type TopicName = BS.ByteString
type TopicNameLen = Word16
type PartitionNumber = Word32
type MessageSetSize = Word32
type NumResponses = Word32

