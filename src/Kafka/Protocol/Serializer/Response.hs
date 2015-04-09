module Kafka.Protocol.Serializer.Response
( 
 buildPrResponseMessage
) where 

import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import qualified Network.Socket.ByteString.Lazy as SBL
import Network.Socket
import Data.Binary.Put
import Kafka.Protocol.Types

--------------------
-- Produce Response (Pr)
--------------------
buildRsPrError :: RsPrError -> BL.ByteString 

buildRsPrError e = runPut $ do 
  putWord32be $ errPartitionNumber e
  putWord16be $ errCode e 
  putWord64be $ errOffset e 

buildRsPrErrors :: [RsPrError] -> BL.ByteString
buildRsPrErrors [] = BL.empty
buildRsPrErrors (x:xs) = BL.append (buildError x) (buildErrors xs)

buildRsPrResponse :: Response -> BL.ByteString
buildRsPrResponse e = runPut $ do 
  putWord16be $ resTopicNameLen e 
  putByteString $ resTopicName e
  putWord32be $ resNumErrors e 
  putLazyByteString $ buildErrors $ resErrors e

buildRsPrResponses :: [Response] -> BL.ByteString
buildRsPrResponses [] = BL.empty 
buildRsPrResponses (x:xs) = BL.append (buildProduceResponse x) (buildProduceResponses xs)

buildPrResponseMessage :: ResponseMessage -> BL.ByteString
buildPrResponseMessage e = runPut $ do 
  putWord32be $ rsCorrelationId e 
  putWord32be $ rsNumResponses e 
  putLazyByteString $ buildPrResponses $ responses e 

--sendProduceResponse :: Socket -> ResponseMessage -> IO() 
--sendProduceResponse socket responsemessage = do 
--  let msg = buildProduceResponseMessage responsemessage
--  SBL.sendAll socket msg

