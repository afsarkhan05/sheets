# Design Pattern

Hello INterview ::::: System Design

- https://www.hellointerview.com/community/submissions

## Design Pattern

- https://www.linkedin.com/feed/update/urn:li:activity:7403736683352838144?utm_source=share&utm_medium=member_desktop&rcm=ACoAAAElazwBoCzbHB1pVw5kEqBXXs5kP8jK5xA

(Design pattern concise)  
🔹 API Gateway Pattern  
🔹 Database per Service  
🔹 Circuit Breaker  
🔹 Service Discovery  
🔹 Event Sourcing  
🔹 CQRS  
🔹 Saga  
🔹 Strangler Fig  
🔹 Bulkhead  
🔹 Sidecar

1. API Gateway :
- a. This can handle single point of contact for all api
- b. Redirecting, Common authorization like jwt verification, Common Logging, Rate Limiting, Throttle etc
- c. Request/Response aggregation
2. Saga, Circuit breaker, Service Discovery, Event Sourcing, CQRS are part of specific service one API gateway redirect to service

**Circuit Breaker:** Resilience4j or Hystrix  
**Event Sourcing:** Kafka, Pub/Sub  
**CQRS:** Agency, Campaign data in MySQl and read from couchbase by dataproc/storm topologies etc  
**Saga:** Saga Orchetration by metadata service  
**Service Discovery:** Eureka, Consul  
**Sidecar:** Kubernetes pod with multi container (logging etc)

Akamai --> Load balancer --> Ingress Controller (nginx or gce) --> Ingress --> Service --> Pod

### One DB per service

Decoupling,Isolation,Scalability,Flexibility

## DB

ACID Properties (Atomicity - All or none, Consistency -> Type same & data , Isolation -> each transaction runs independently, Durable -> once commited stays in db)

Partition (Same DB server , partition data by column like date/user, like vertical scaling)  
Sharding (Multi server, partition one servers like horizontal scaling)  
Replication (copy the data on another server as redundancy)  
Cluster (sharding + replication together on multi server)
