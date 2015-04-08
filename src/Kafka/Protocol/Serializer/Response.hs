module Kafka.Protocol.Serializer.Response
( sendProduceResponse 
) where 

import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import qualified Network.Socket.ByteString.Lazy as SBL
import Network.Socket
import Data.Binary.Put
import Kafka.Protocol.Types

buildError :: Error -> BL.ByteString 
buildError e = runPut $ do 
  putWord32be $ errPartitionNumber e
  putWord16be $ errCode e 
  putWord64be $ errOffset e 

buildErrors :: [Error] -> BL.ByteString
buildErrors [] = BL.empty
buildErrors (x:xs) = BL.append (buildError x) (buildErrors xs)

buildProduceResponse :: Response -> BL.ByteString
buildProduceResponse e = runPut $ do 
  putWord16be $ resTopicNameLen e 
  putByteString $ resTopicName e
  putWord32be $ resNumErrors e 
  putLazyByteString $ buildErrors $ resErrors e

buildProduceResponses :: [Response] -> BL.ByteString
buildProduceResponses [] = BL.empty 
buildProduceResponses (x:xs) = BL.append (buildProduceResponse x) (buildProduceResponses xs)

buildProduceResponseMessage :: ResponseMessage -> BL.ByteString
buildProduceResponseMessage e = runPut $ do 
  putWord32be $ resCorrelationId e 
  putWord32be $ resNumResponses e 
  putLazyByteString $ buildProduceResponses $ responses e 

sendProduceResponse :: Socket -> ResponseMessage -> IO() 
sendProduceResponse socket responsemessage = do 
  let msg = buildProduceResponseMessage responsemessage
  SBL.sendAll socket msg

