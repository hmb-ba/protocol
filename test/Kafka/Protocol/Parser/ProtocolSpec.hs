module Kafka.Protocol.Parser.DataSpec where
  
import SpecHelper 
import Data.Binary.Get
import qualified Data.ByteString.Lazy.Char8 as BL 
import qualified Data.ByteString.Char8 as BS
import Kafka.Protocol.Types
import Kafka.Protocol.Serializer.Data

spec :: Spec 
spec = do 
  describe "Kafka.Protocol.Parser.Data" $ do
    context "parseMessageSet" $ do 
      it "parses exactly as-is" $ do 
        let ms = getMessageSetFixture $ getMessageFixture $ getPayloadFixture "Test"
        testSerializeParseMessageSet ms 

main :: IO() 
main = hspec spec

--aparse (Eq a, Show a) =>(a -> BL.ByteString) -> a 
--parse f ()= f

testSerializeParseMessageSet :: MessageSet -> Expectation
testSerializeParseMessageSet m = (runGet messageSetParser $ buildMessageSet m) `shouldBe` m



