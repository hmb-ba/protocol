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
        let content = BS.pack("some simple Text")
        let message = MessageSet 0 0 $ Message 0 $ Payload 0 0 0 (fromIntegral $ BS.length $ content) content
        let input = buildMessageSet message

        (runGet messageSetParser input) `shouldBe` message

main :: IO() 
main = hspec spec


