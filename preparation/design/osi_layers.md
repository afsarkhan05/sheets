# OSI Layers

Application Layer -> Data (e.g., HTTP request/response) -> Not typically headers added by the protocol itself, but application may add metadata.  
Transport Layer -> TCP header (for TCP)/UDP header (for UDP) -> Contains source/destination port numbers, sequence numbers, error-checking info.  
Security Layer -> TLS/SSL handshake messages, and then encrypted data -> Establishes secure session,manages encryption keys& encrypts app data.  
Network Layer -> IP header -> Contains source/destination IP addresses, routing info.  
Data Link Layer -> Ethernet frame header, MAC addresses -> Used for local delivery, contains physical addressing, frame control info.  
Physical Layer -> Bits transmitted over physical medium -> Actual signals (electrical, optical, radio waves); no headers in the bits.

## Security

Encryption  
**Purpose:** To convert plaintext into ciphertext to keep data secret.  
**Reversibility:** Reversible; data can be decrypted back to original.  
**Use Case:** Confidential data transmission, data protection.

### Types

Symmetric encryption (e.g., AES): same key for encryption and decryption.  
Asymmetric encryption (e.g., RSA): public key for encryption, private key for decryption.

2. Hashing

**Purpose:** To generate a fixed-length hash value (digest) from data, mainly for integrity verification.  
**Reversibility:** Irreversible; cannot recover original data from hash.  
**Use Case:** Password storage, data integrity checks.  
**Common algorithms:** MD5, SHA-1, SHA-256, SHA-3.

3. Digital Signature

**Purpose:** To verify the authenticity and integrity of a message or document.  
**Reversibility:** Not reversible; verification is done using public key.  
**Process:** Typically involves hashing the message, then encrypting the hash with a private key.  
**Use Case:** Authentication, non-repudiation.  
**Example:** Signing an email with your private key., JWT token

4. Encoding

**Purpose:** To transform data into a different format for safe transmission or storage.  
**Reversibility:** Reversible; data can be decoded back to original.  
**Use Case:** Data formatting (Base64 encoding for email, URL encoding).  
**Difference:** Not used for security, just for data representation.  
**Common:** Base64, Base62

## GENERIC OSI

**API:** It's communication between 2 software based on predefined rules, protocol  
**gRPC:** Client server communication, one component (the client) calls or invokes specific functions in another software component (the server)  
It calls the funtion on server by passing parameter. Using TCP/UDP/HTTP protocol

**Rest API:** RESTful APIs manage communications between a client and a server through HTTP verbs, like POST, GET, PUT,  
and DELETE for create, read, update, and delete operations. The server-side resource is identified by a URL known as an endpoint.

### Monolithic vs Microservices

1. Problem with scalability as it needs scaling all the component, microser: we can independntly scala specific component based on traffic/needs
2. Huge code base, makes complexicity
3. Due to above, hard to try alternatives/new ideas
4. small team, easy, fast deployment, rollout

Agility, easy deployment, scaling, flexibility, Code reuse, resilience

**UDP (User Datagram Protocol):** No connection needed before send/receive data. best where data loss is ok, video call/ game data etc  
User Datagram Protocol(UDP) is a connectionless, fast and simple protocol for sending data packets over the internet.  
UDP packets may be lost or received out of order, which can result in some loss of data quality or completeness,  
making it suitable for real-time applications like voice and video streaming or online gaming.

### TCP (Transmission Control Protocol)

This helps in connection between client/server for communication.  
TCP, on the other hand, is a reliable, connection-oriented protocol responsible for ensuring data delivery.  
When data is sent via TCP, it creates a virtual connection to ensure that packets arrive in the correct order and completeness.  
TCP sets up a connection via a three-way handshake and uses sequencing to make sure that all data arrives accurately and in the correct order.

TCP and UDP are transport layer protocols responsible for data delivery between applications.  
TCP offers connection-oriented, reliable data delivery, ensuring packets are delivered in a certain order.  
UDP is fast and simple for data transfer and includes no such reliability measures.  
Unlike TCP, UDP doesn't wait for all packets to arrive or organize the packets.  
Instead, UDP transmits all packets even if some haven't arrived.  
UDP solely transmits packets, while TCP transmits,  
organizes and ensures the packets arrive. While UDP works more quickly than TCP, it's also less reliable.

HTTP only defines common "language" for client and server, but not how to send data

HTTP(Insecure) and HTTPS (Secured TSL/SSL + HTTP = HTTPS)  
HTTP/HTTPS uses TCP or UDP for communication between server-client

### Http / Https (http+ssl/tsl)call

Client <------Connection with TCP/SSL------> Server

**FTP:** Client server protocol to transfer files, FTP runs over TCP/IP  
**SMTP:** for sending email from client  
**IP:** To identify a resource, unique resource  
**Telnet:** remote connection

- https://superuser.com/questions/1411701/http-vs-tcp-vs-udp-with-this-example
