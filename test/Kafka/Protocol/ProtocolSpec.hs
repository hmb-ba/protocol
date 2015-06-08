module Kafka.Protocol.ProtocolSpec where

import SpecHelper
import Data.Binary.Get
import Data.Binary.Put
import qualified Data.ByteString.Lazy.Char8 as BL
import qualified Data.ByteString.Char8 as BS

import Kafka.Client

spec :: Spec
spec = do
  describe "Kafka.Protocol" $ do
    context "MessageSet" $ do
      it "Test1: Default Value" $ do
        let ms = getMessageSetFixture $ getMessageFixture $ getPayloadFixture "Test"
        testMs ms
      it "Test2: No Value" $ do
        let ms = getMessageSetFixture $ getMessageFixture $ getPayloadFixture ""
        testMs ms
      it "Test3: Value with special characters" $ do
        let ms = getMessageSetFixture $ getMessageFixture $ getPayloadFixture "[*+!^^!{}//\\%ç]"
        testMs ms
      it "Test4: JSON Value" $ do
        let ms = getMessageSetFixture $ getMessageFixture $ getPayloadFixture "[ obj : { value : 123 }]"
        testMs ms

    context "ProduceRequest" $ do
      it "Serialize/Parse: No Topic" $ do
        let r = getRequestMessageFixture $ getProduceRequestFixture []
        testPrRq r

      it "Serialize/Parse: One Topic, No Partition" $ do
        let t = getTopicFixture "A" []
        let r = getRequestMessageFixture $ getProduceRequestFixture [t]
        testPrRq r

      it "Serialize/Parse: Multi Topic, No Partition" $ do
        let t1 = getTopicFixture "A" []
        let t2 = getTopicFixture "B" []
        let t3 = getTopicFixture "C" []
        let r = getRequestMessageFixture $ getProduceRequestFixture [t1, t2, t3]
        testPrRq r

      it "Serialize/Parse: One Topic, One Partition, No MessageSet" $ do
        let p = getRqPrPartitionFixture []
        let t = getTopicFixture "A" [p]
        let r = getRequestMessageFixture $ getProduceRequestFixture [t]
        testPrRq r

      it "Serialize/Parse: One Topic, Multi Partition, No MessageSet" $ do
        let p =  getRqPrPartitionFixture  []
        let t = getTopicFixture "A" [p, p, p]
        let r = getRequestMessageFixture $ getProduceRequestFixture [t]
        testPrRq r

      it "Serialize/Parse: One Topic, One Partition, One MessageSet" $ do
        let ms = getMessageSetFixture $ getMessageFixture $ getPayloadFixture "Test"
        let p = getRqPrPartitionFixture [ms]
        let t = getTopicFixture "A" [p]
        let r = getRequestMessageFixture $ getProduceRequestFixture [t]
        testPrRq r

      it "Serialize/Parse: One Topic, One Partition, Multi MessageSet" $ do
        let ms = getMessageSetFixture $ getMessageFixture $ getPayloadFixture "Test"
        let p = getRqPrPartitionFixture [ms, ms, ms]
        let t = getTopicFixture "A" [p]
        let r = getRequestMessageFixture $ getProduceRequestFixture [t]
        testPrRq r

      it "Serialize/Parse: One Topic, One Partition, One MessageSet" $ do
        let ms = getMessageSetFixture $ getMessageFixture $ getPayloadFixture "Test"
        let p = getRqPrPartitionFixture [ms, ms, ms]
        let t1 = getTopicFixture "A" [p,p,p]
        let t2 = getTopicFixture "B" [p,p,p]
        let t3 = getTopicFixture "C" [p,p,p]
        let r = getRequestMessageFixture $ getProduceRequestFixture [t1, t2, t3]
        testPrRq r

main :: IO()
main = hspec spec

testMs :: MessageSet -> Expectation
testMs m = (runGet messageSetParser $ runPut $ buildMessageSet m) `shouldBe` m

testPrRq :: RequestMessage -> Expectation
testPrRq req = (runGet requestMessageParser $ runPut $ buildRqMessage req) `shouldBe` req



