module Kafka.Client.Consumer 
(
) where

-- packTopic :: String -> [Partition] -> Topic
-- packTopic t ps = Topic
--   (fromIntegral $ BS.length t)
--   t
--   (fromIntegral $ length ps)
--   ps
-- 
-- packFtRequest :: -> FetchRequest
-- packFtRequest = FetchRequest 
--   0
--   0
--   -- todo: weiter hier
-- 
-- packFtRequestMessage :: InputFt -> RequestMessage
-- packFtRequestMessage iM = Requestmessage {
--       rqSize = fromIntegral $ (BL.length $ buildProduceRequestMessage packFtRequest )
--           + 2 -- reqApiKey
--           + 2 -- reqApiVersion
--           + 4 -- correlationId 
--           + 2 -- clientIdLen
--           + (fromIntegral $ BS.length $ inputClientId iM) --clientId
--     , rqApiKey = 0
--     , rqApiVersion = 0
--     , rqCorrelationId = 0
--     , rqClientIdLen = fromIntegral $ BS.length $ inputClientId iM
--     , rqClientId = inputClientId iM
--     , rqRequest = produceRequest
--   }

