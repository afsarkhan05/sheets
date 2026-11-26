# GC JMM

Garbage collection - Automatic once object/variable has no reference  
1 Method Memory - variable, class , method names plus all static variable name and value stored  
2 Stack Memory - All method level variables are stored  
3 Heap Memory - All Instance and instance variables are stored  
4 PC Register - Every thread has specific memory location  
4 String pool

metaspace = static block and variables  
heap (gc) = all objects, instance variables  
stack = local variables, local object reference only, primitive  
string pool = specialized heap area for string pools object

G1GC vs ZGC  
G1GC => split heap into small pieces and find which one is full to act for cleaning  
ZGC => concurrently work so highly fast, scalable

### Heap

```text
├── Young Generation
│    ├── Eden space       (new objects allocated here)
│    ├── Survivor S0
│    └── Survivor S1
└── Old Generation (Tenured) — long-lived objects promoted here after surviving N minor GCs
```

Metaspace (off-heap, replaced PermGen since Java 8) — class metadata  
Stack (per-thread) — local vars, method frames  
Native/off-heap — direct ByteBuffers, JNI

**Q:** "Why did PermGen get replaced with Metaspace in Java 8?"  
PermGen had a fixed max size (-XX:MaxPermSize), causing frequent OutOfMemoryError: PermGen space in apps with heavy classloading (e.g., app servers redeploying WARs repeatedly, or frameworks generating many dynamic proxy classes). Metaspace uses native (off-heap) memory, growing dynamically by default — removes that artificial ceiling, though you can still cap it with -XX:MaxMetaspaceSize to avoid native memory exhaustion.

**Q:** "Why can two different instances of the 'same' class (same fully-qualified name) coexist in one JVM?"  
A class's runtime identity in the JVM is actually (fully-qualified name, ClassLoader instance) — the same class loaded by two different class loaders is treated as two distinct types, and you'll get ClassCastException: X cannot be cast to X (same name, different loader) — a classic interview "trick question" that trips people up, and a real issue in app-server/plugin architectures (OSGi, Tomcat's per-webapp loaders).

- transient belongs to the world of Serialization (saving objects to disk or sending them over a network - The Serialization(marker interface) Skip)
- volatile belongs to the world of Concurrency (multi-threading, CPU caches, and memory visibility)

G1GC (Garbage First - Then delete)

1. Concurrent Marking (Live Background): While your Spring Boot code is handling API requests, G1GC background threads are quietly marking which objects are alive across the regions. (Zero pause time here!)
2. **Evacuation (The Micro-Pause):** When it's time to reclaim space, G1GC halts your application threads for a split second. It grabs the few surviving objects from the target garbage regions, copies them cleanly into a brand-new, empty region, and completely wipes the old regions clean in one massive stroke.

Just like G1GC, ZGC chops the total heap memory into small blocks [home-services-diy]. But instead of "Regions," ZGC calls them Pages.

- G1GC Regions are all the exact same size.
- ZGC Pages dynamically scale into three different sizes depending on how big your objects are: Small Pages (2MB for small objects), Medium Pages (32MB), and Large Pages (variable size, dynamically allocated to fit one single massive object).

In G1GC, when the collector moves a living object to a new room, it has to freeze the application (Stop-The-World) to rewrite all the memory addresses pointing to that object. If it didn't freeze the code, a worker thread might look at an old pointer address and try to read an object that isn't there anymore.  
ZGC solves this by inventing Colored Pointers.  
On a 64-bit modern computer server, a standard memory pointer address only needs about 42 to 44 bits to physically locate any spot in RAM. The rest of the bits are usually wasted zeroes.  
ZGC steals 4 of those empty bits inside every object reference pointer and uses them as physical color flags (e.g., Marked0, Marked1, Remapped).

G1GC for low memory because, it stop the watch so no new object get created during that time of clean up. But if we use ZGC on low memory size which  
continuously do cleaning without stop-watch means during cleaning if more objects are getting created then destroyed we will end of OOM error.

Live - S1 - S2 (Survivor) - Long /Old

```text
Feature                                                G1GC                                                    ZGC
Cleaning Style             Pauses the application to copy                               Copies objects concurrently while your
                        objects to fresh regions.                                        application threads are running.
How it protects data?      Freezes the clock (Stop-The-World).                              Uses Colored Pointers and Load Barriers
```

to self-heal references on the fly.  
Pause Time?                Low (10ms to 200ms depending on heap size).                      Ultra-Low (< 1ms) regardless of whether your

- heap is 10GB or 16 Terabytes!

When ZGC decides to compact a page (region) to free up memory, it copies live objects to a new page.

- Because the object moves to a completely new physical memory address, the old reference pointer must change.
- To prevent application threads from breaking, ZGC leaves behind a forwarding table mapping the old address to the new address.

"Self-Healing" via Load Barriers

Instead of pausing the entire application to update every single pointer in memory at once, ZGC updates them on the fly (concurrently) using a Load Barrier.  
When your application code tries to read a reference from memory:

1. **The Check:** The load barrier checks the "color" bits of the pointer. If the bits show the pointer is already Remapped, it reads it instantly with zero overhead.
2. **The Catch:** If the bits indicate a relocation is happening, the barrier checks the forwarding table.
3. **The Fix:** If the object has been moved, the load barrier dynamically updates (heals) the reference pointer in place to point to the new address and changes its color to Remapped.

- The old object memory (Page A): Deleted immediately after all 10 objects are copied to the new page.
- The reference mapping (Forwarding Table): Deleted at the start of the next GC cycle, once ZGC guarantees every pointer has been updated.
- **G1GC (The Batch Processor):** G1GC tries to be smart about when it pauses your application. It acts like a city cleanup crew that monitors garbage bins (regions) and waits until they are full. When it's time to empty them, it temporarily blocks the street (stops the clock), quickly throws the good stuff into new bins (Eden, Survivor S1/S2, Old), and deletes the garbage before letting traffic move again.
- **ZGC (The Continuous Flow):** ZGC assumes that stopping traffic is unacceptable. It acts like a cleanup crew that works alongside active traffic. It moves objects to new pages on the fly. If a car (your app thread) happens to run into an old address, the car itself instantly updates its own map (self-healing via the load barrier) without dropping its speed.

zgc and g1gc is zgc continuously and concurrently working and keep moving object to other pages and delete unused object to free space without stoping the clock or app. Similarly g1gc working in 2 ways, first working on region and finding and classify object as live, s1,s2, or long and keep region metadata and when it needs GC process to run due to low memory etc it will find the top regions from metadata which can be cleaned up and stop the clock and freeze the app and delete those object and move object and fix their new pointer ref?

While everything you create with the new keyword lands on the Java Heap, there is a massive chunk of your server's RAM used by Java that sits completely outside the Heap. This is called Off-Heap Memory.

A. Metaspace (The Blueprint Library)

When you load a class file, a compiled record, or an interface layout into your Spring Boot app, the code blueprints don't go to the Heap. They are saved in the Metaspace.

- **What lives here:** Class definitions, method bytecode instructions, the constant pool, and static variables.

"ZGC requires more memory headroom because it suffers from a phenomenon known as Allocation Stall Space Overhead.  
Because ZGC relocates and sweeps memory pages concurrently while application threads are actively running, your Spring Boot code is continuously creating new objects on the heap at the exact same time the garbage collector is trying to free up space.

If your application has a high object allocation rate, ZGC needs a massive temporary memory buffer on the heap to absorb those incoming objects while its background threads complete a cleaning cycle. If the heap is too small and the application fills memory faster than ZGC can clean it, the JVM will experience an Allocation Stall—freezing your application threads entirely until the collector catches up.  
G1GC avoids this high headroom requirement because it pauses the application clock entirely during major collection phases, meaning no new garbage is being created while it executes a sweep."

When a production server spikes to 100% CPU, freezes completely, or runs out of memory, senior engineers don't guess. They use Thread Dumps, Heap Dumps, and Profilers to look directly at the living JVM engine.

- **Old Java:** High Latency + Memory Bloat because every thread interaction forces a context switch into Kernel Space, backed by rigid 1MB Native Stacks.
- **Modern Java:** High Throughput + High Efficiency because thread interactions are managed entirely in User Space as elastic, dynamic Heap Objects, keeping the physical Carrier Threads running at 100% capacity.
- Metaspace (PermGen) = The Container Image: Just like a Docker/K8s image, Metaspace holds the immutable blueprint. It contains the compiled bytecode, class structures, method definitions, and the instructions on how an object should behave. It is read-only during normal execution; you don't "run" code inside the image itself.
- Heap Objects = The Running Pods/Containers: When K8s spins up 5 replicas of a pod from a single image, it allocates memory, CPU, and a distinct lifecycle to each container. Similarly, when you call new MyClass(), the JVM uses the Metaspace "image" to stamp out a living, breathing object instance on the Heap. You can have thousands of unique object instances (containers) all sharing and referencing a single class definition (image).

JMM consists of Metaspace (class, bytecode, blueprint as metadata) , Heap (All types of object, static variable, string pool etc), Stack (all local method frames, local primitive variable, local object (but only ref pointer of heap))

find process id then thread id then thread dump using profiler then convert thread id to hex and find that hex in thread dump to figure out what's happening  
also heap dump will give you each object on heap and how much memory it's consuming

new relic jar is added as javaagent while running "java" command for spring boot container

- **Bytecode Instrumentation:** When the JVM boots up and loads your Spring Boot class blueprints into the Metaspace, the New Relic Agent intercepts them. It uses a low-level technique called bytecode manipulation to inject tiny tracking timers around your @RestController methods, database calls, and thread execution paths.
- **The Data Pipeline:** Every few seconds, the agent aggregates these metrics and ships them asynchronously over HTTPS out of your Kubernetes cluster to New Relic's cloud servers.

Instead of manually running commands after a server is already dead, senior architects configure the JVM inside the Dockerfile to automatically trigger a heap dump the exact millisecond it runs out of memory before the pod gets killed by Kubernetes:

- Inside your Dockerfile or K8s deployment env configurations

ENV JAVA_TOOL_OPTIONS="-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/tmp/crash_dump.hprof"

Datadog's Continuous Profiler continuously takes tiny, 1% overhead thread snapshots behind the scenes (datadog and new relic both are javaagent)

When you create a corporate account with Datadog or New Relic, you are generated a unique, high-security cryptographic string called an API Key or License Key

in k8s deployment.xml we pass api (data dog or new relic) using k8s secret which will be used by agent attached to container to send telemetry data on their cloud which can be viewed from browser with account attached to that api key.
