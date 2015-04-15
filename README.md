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

Metadata API
Produce API
Fetch API
Offset API
Offset Commit/Fetch API

### Serializer

## Client Library

### Consumer

### Producer
