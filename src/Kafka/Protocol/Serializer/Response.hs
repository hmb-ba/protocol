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
  putWord32be $ rsPrPartitionNumber e
  putWord16be $ rsPrCode e 
  putWord64be $ rsPrOffset e 

buildRsPrErrors :: [RsPrError] -> BL.ByteString
buildRsPrErrors [] = BL.empty
buildRsPrErrors (x:xs) = BL.append (buildRsPrError x) (buildRsPrErrors xs)

buildProduceResponse :: Response -> BL.ByteString
buildProduceResponse e = runPut $ do 
  putWord16be $ rsPrTopicNameLen e 
  putByteString $ rsPrTopicName e
  putWord32be $ rsPrNumErrors e 
  putLazyByteString $ buildRsPrErrors $ rsPrErrors e

buildProduceResponses :: [Response] -> BL.ByteString
buildProduceResponses [] = BL.empty 
buildProduceResponses (x:xs) = BL.append (buildProduceResponse x) (buildProduceResponses xs)

buildPrResponseMessage :: ResponseMessage -> BL.ByteString
buildPrResponseMessage e = runPut $ do 
  putWord32be $ rsCorrelationId e 
  putWord32be $ rsNumResponses e 
  putLazyByteString $ buildProduceResponses $ rsResponses e 

--sendProduceResponse :: Socket -> ResponseMessage -> IO() 
--sendProduceResponse socket responsemessage = do 
--  let msg = buildProduceResponseMessage responsemessage
--  SBL.sendAll socket msg

