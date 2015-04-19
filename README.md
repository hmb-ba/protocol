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

We basically separate between three kind of types:
 1. Related to request
 2. Related to response
 3. Related to data (for either request or response but can also be used for the [Apache Kafka Log](http://kafka.apache.org/documentation.html#log) component since log files (on-disk) hold the same structure - which is awesome!)
 
The following table gives an overview about the naming convention used within this package as well as the different kind of data types available for requests and responses:

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

#### Request

To determine the type of request, the Apache Kafka protocol describes an [Api Key](https://cwiki.apache.org/confluence/display/KAFKA/A+Guide+To+The+Kafka+Protocol#AGuideToTheKafkaProtocol-ApiKeys) field which holds a numeric code to determine the type of request. 

We thus provide a function **readRequest** which gives an **IO RequestMessage** that allows to handle the request based on the **rqApiKey** field: 

```haskell
requestMessage <- readRequest i
case rqApiKey requestMessage of
    0  -> handleProduceRequest (rqRequest requestMessage)
    1  -> handleFetchRequest (rqRequest requestMessage)
    ...
```

#### Response

### Serializer

Obviously the serializer is provides the opposite functionalities as the parser and was separated just for clarity. Thus we also rely on Data.Binary and use the Put Monad ([Data.Binary.Put](https://hackage.haskell.org/package/binary-0.4.3.1/docs/Data-Binary-Put.html)) to construct ByteStrings.

#### Request

As for now, we provide build functions for every kind of request. Probably a more intuitive way to do so, is to determine the type of request based on the *rqApiKey* provided in the message header - basically the same way we do for parsing. See [issue](https://github.com/hmb-ba/protocol/issues/1).

#### Response

## Client Library

The client libary provides functionalities to easily implement an Apache Kafka client in Haskell. The goal of this, is to be able to setup a client without knowing too much details about the Apache Kafka protocol itself.

### Consumer



### Producer
