# Apache Kafka Protocol in Haskell

This package covers the Apache Kafka protocol (version **0.8 and beyond**) implementation, written in Haskell. 
This includes: **types**, **parsing** and **serializing** for the given [APIs](https://cwiki.apache.org/confluence/display/KAFKA/A+Guide+To+The+Kafka+Protocol#AGuideToTheKafkaProtocol-TheAPIs).
On top of this, a client library is provided which can be used to build consumer and producer clients.

### Current State

- [ ] Metadata API
  - [x] Topic Metadata Request
  - [ ] Metadata Response
- [x] Produce API
    - [x] Produce Request
    - [x] Produce Response
- [x] Fetch API
  - [x] Fetch Request
  - [x] Fetch Response
- [ ] Offset API
  - [ ] Offset Request
  - [ ] Offset Response
- [ ] Offset Commit/Fetch API
  - [ ] Consumer Metadata Request
  - [ ] Consumer Metadata Response
  - [ ] Offset Commit Request
  - [ ] Offset Commit Response
  - [ ] Offset Fetch Request
  - [ ] Offset Fetch Response

## Protocol Library

### Types

| API                     | Request (Rq)        | Response (Rs)         |
| ----------------------- |:-------------------:| :--------------------:|
| Metadata API (Md)       | MetadataRequest     | MetadataResponse      |
| Produce API (Pr)        | ProduceRequest      | ProduceResponse       |
| Fetch API (Ft)          | FetchRequest        | FetchResponse         |
| Offset API (Of)         | OffsetRequest       | OffsetResponse        |
| Offset Commit API (Ofc) | OffsetCommitRequest | OffsetCommitResponse  |
| Offset Fetch API (Oft)  | OffsetFetchRequest  | OffsetFetchResponse   |

TODO: ConsumerMetadataRequest?!

### Parser

As for binary serialization, we rely the [Data.Binary](https://hackage.haskell.org/package/binary-0.4.1/docs/Data-Binary.html#t:Binary) library. 
Using the Get Monad ([Data.Binary.Get](https://hackage.haskell.org/package/binary-0.4.3.1/docs/Data-Binary-Get.html)) we are able to comfortablyparse ByteString in it's big endian network order and decode it to appropriate types.

#### Request

To determine the type of request, the Apache Kafka protocol describes an [Api Key](https://cwiki.apache.org/confluence/display/KAFKA/A+Guide+To+The+Kafka+Protocol#AGuideToTheKafkaProtocol-ApiKeys) field which holds a numeric code to determine the type of request. 

We thus provide a function **readRequest** which gives an **IO RequestMessage** that allows to handle the request based on the **apiKey** field: 

```haskell
requestMessage <- readRequest i
case rqApiKey requestMessage of
    0  -> handleProduceRequest (rqRequest requestMessage)
    1  -> handleFetchRequest (rqRequest requestMessage)
    ...
```

### Serializer

## Client Library

### Consumer

### Producer
