# Thread

Task = Runnable, Callable (Return)  
Executor = ExecutorService (normalServiceWorker, maxWorker, QueuedSize, rejectionType)  
OR create thread for task  
Virtual Thread with synchronized kills the purpose of virtual thread as it pushes on OS/Platform thread  
Virtual Thread => managed by jvm run on os thread, but jvm do mount/unmount

- jvm move data from virtual thread to heap and free up os thread for another virtual thread
    - virtual thread is also called carrier thread

```java
new ThreadPoolExecutor(
    corePoolSize, maxPoolSize, keepAliveTime, TimeUnit.SECONDS,
    new ArrayBlockingQueue<>(boundedCapacity),     // bounded queue
    new ThreadPoolExecutor.CallerRunsPolicy()        // explicit rejection policy
);
```

If activeThreads < corePoolSize → create new thread (even if idle threads exist).  
Else, try to queue the task.  
If the queue is full AND activeThreads < maxPoolSize → create a new thread beyond core size.  
If queue is full AND at maxPoolSize → invoke the RejectedExecutionHandler.

- volatile belongs to the world of Concurrency (multi-threading, CPU caches, and memory visibility)

"If I have a volatile int counter = 0; and multiple threads call counter++, is it thread-safe?"

- NO, volatile only guarantees visibility (reading the latest value). It does not guarantee atomicity (protecting a multi-step operation)
- **The Fix:** For calculations, you must use synchronized blocks or atomic classes like AtomicInteger

Think of a Future like a claim ticket at a coat check:

1. You hand your Callable worker to a thread pool.
2. The pool immediately hands you back a Future object on the heap (your claim ticket).
3. The background thread goes off to do the math.
4. Meanwhile, your main thread can continue running other code.
5. When your main thread finally needs the data, it calls future.get(). If the background thread is finished, it pulls the calculated object off the heap and hands it to you. If it's still working, your main thread politely pauses and waits until the data is born.

Thread.join() is an explicit command that tells the currently executing thread (usually your Main Thread) to freeze and wait until a specific background thread finishes its work completely.

so basically thread.join will wait for child thread to finish and freezes the main thread and won't move until other threads finished.

whereas, callable future will give you a heap pointer of object which will be a result of child thread once finishes, when you call future.get jvm actually trying to give you data available on heap under that pointer object?

Instead of forcing the main thread to stand there and wait with .get(), CompletableFuture allows you to attach a callback function (a Functional Interface worker!) directly onto the heap container

**You tell the JVM:** "Hey, Main Thread is moving on to do other things. Background Thread, the split-second you finish creating that object on the heap, automatically pass it to this next worker to handle it. Do not bother the main thread!"
