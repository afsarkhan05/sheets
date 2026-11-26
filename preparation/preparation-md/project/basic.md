# Basic

## History

1. Reporting Application with Netezza and Oracle deployed on Jboss
2. Metadata monolithic app used on Wildfly server on prem using Jenkins
3. Moved the monolithic app using wildfly image deployed on DockerSwarm
4. Started migrating to microservices dockerized with Redis and deployment on K8S
5. Used Saga (within services using Kafka), Service Discovery and Circuit breaker for synch calls to tag r
6. Deployment using Helm, creating deployement started using k8s configMap, secret, secretManagers etc
7. Moved to Memory Store instead of Redis, Pub/Sub instead of Kafka
8. Upgraded to jdk 17 and spring 3.x moved to OpenAPI 3.0 swagger UI
9. Okta JWT Token instead of alpha zulu internal system

"Initially, we handled dual-writes within the API service layer. However, we recognized this created a distributed transaction problem and tightly coupled our UI write paths to Couchbase availability.  
To fix this, we evolved the architecture toward an asynchronous, event-driven pattern."
