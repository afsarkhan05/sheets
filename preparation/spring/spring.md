# Spring

## Resilience4J

### Resilience4J with spring

Circuit Breaker, Retry, Rate Limiter, Time Limiter, and Bulkhead

1. **Singleton:** One shared instance per container. Cannot hold state unique to an individual execution thread.
2. **Prototype:** Fresh instance every request. If injected into a Singleton, it must use a ScopingProxyMode to function correctly.
3. **CGLIB Proxies:** Spring creates a dynamic subclass of your bean at runtime to intercept method calls.
4. **Self-Invocation:** Inter-method calls inside the same class completely bypass proxy boundaries, rendering annotations like @Transactional or @Async entirely useless.

2 ways to correctly use proxy

1. either push the method into another bean so proxy works OR
2. @Lazy // 💡 Prevents a boot-time circular dependency crash

```java
private OrderService selfProxy;
```

**Q:** "Why do senior engineers insist on constructor injection over field injection?"

Immutability — fields can be final, guaranteeing they're set once and never reassigned.  
Fail-fast — missing dependency fails at object construction time (compile-time if you forget to pass arg, or immediate startup failure), vs field injection which creates a half-built object that fails later/mysteriously (e.g., NullPointerException at first use, not at startup).  
Testability — you can new OrderService(mockPaymentClient, mockRepo) in a plain unit test with no Spring context needed at all. Field injection requires reflection hacks (ReflectionTestUtils) or a full Spring context in tests.  
Reveals design smells — a constructor with 8 parameters screams "this class violates Single Responsibility Principle"; field injection hides this because there's no visual pile-up.  
Prevents circular dependency issues from being silently "resolved" — constructor injection fails fast on circular deps; field/setter injection can mask them via early bean exposure (see below).

| 3. Bean Scopes | SCOPE BEHAVIOR |
|---|---|
| singleton (default) | One instance per Spring container |
| prototype | New instance every time it's requested/injected |
| request | One instance per HTTP request (web-aware context) |
| session | One instance per HTTP session |
| application | One instance per ServletContext |
| websocket | One instance per WebSocket session |

**Q:** "Classic gotcha — injecting a prototype bean into a singleton bean. What goes wrong?"

The singleton is created once, so its prototype dependency is also injected once at that time — you get the same prototype instance forever, defeating the purpose. Fix options:

Lookup method injection (@Lookup) — Spring overrides an abstract method via CGLIB to fetch a fresh prototype bean each call.  
Inject an `ObjectProvider<T>`/`ObjectFactory<T>` and call .getObject() each time you need a fresh instance.  
Inject the ApplicationContext itself and call getBean() (less clean, more coupling).

```java
@Component
public abstract class SingletonService {
    public void process() {
        PrototypeBean bean = createPrototypeBean(); // fresh instance each call
        bean.doWork();
    }
    @Lookup
    protected abstract PrototypeBean createPrototypeBean();
}
```

**PART B:** Bean Lifecycle — a must-know diagram for seniors

1. Bean definition loaded (from @Component scan, @Bean methods, XML)
2. Instantiation (constructor called)
3. Populate properties (dependency injection - setter/field)
4. Aware interfaces invoked (BeanNameAware, BeanFactoryAware, ApplicationContextAware...)
5. BeanPostProcessor.postProcessBeforeInitialization()  <-- @Autowired, @Value processing happens here (AutowiredAnnotationBeanPostProcessor)
6. @PostConstruct / InitializingBean.afterPropertiesSet()
7. Custom init-method (if specified)
8. BeanPostProcessor.postProcessAfterInitialization()  <-- AOP proxies created HERE (e.g., for @Transactional, @Async, @Cacheable)
9. Bean is ready and in use
10. (On shutdown) @PreDestroy / DisposableBean.destroy() / custom destroy-method

**Q:** "Where exactly does Spring create a proxy for @Transactional, and why does that location matter?"

In postProcessAfterInitialization — after the actual target bean has been fully constructed and initialized. This means the object your application code actually gets injected (from @Autowired) is a proxy wrapping the real bean, not the real bean itself. This is foundational for understanding the self-invocation problem (below).

The infamous "self-invocation breaks @Transactional/@Async/@Cacheable" gotcha

```java
@Service
public class OrderService {
    public void placeOrder(Order order) {
        this.saveOrder(order); // calling "this.saveOrder" bypasses the proxy entirely!
    }

    @Transactional
    public void saveOrder(Order order) { /* ... */ }
}
```

**Q:** "Why doesn't @Transactional apply here?"

Spring AOP (default: proxy-based, not compile-time weaving) only intercepts calls that go through the proxy object — i.e., calls arriving from outside the bean. A call via this.method() from inside the same object calls the method directly on the raw target, completely bypassing the proxy, so the transactional advice never triggers. This is one of THE most common real production bugs with Spring, and a favorite interview question.

### Fixes

Move the @Transactional method to a separate bean/service and inject that.  
Self-inject via @Autowired a reference to itself (get the proxy back) — works but is a code smell.  
Use AopContext.currentProxy() after enabling exposeProxy=true — ((OrderService) AopContext.currentProxy()).saveOrder(order).  
JDK Dynamic Proxy vs CGLIB — when does Spring pick which?  
If the bean implements at least one interface → JDK dynamic proxy (implements the same interfaces, java.lang.reflect.Proxy).  
If the bean has no interface (concrete class only) → CGLIB proxy (subclasses the target class at runtime via bytecode generation).  
Spring Boot 2+ defaults to always using CGLIB (spring.aop.proxy-target-class=true by default) for consistency, even when interfaces exist.  
**Q:** "Why would CGLIB proxying fail, and what's the fix?"

CGLIB works by subclassing — so:

The target class cannot be final (can't subclass a final class).  
The method being proxied cannot be private or final (can't override it).  
The class needs a default/accessible constructor (CGLIB historically needed this; modern versions with objenesis can bypass it, but it's still best practice).  
**PART C:** AOP (Aspect-Oriented Programming)  
java

```java
@Aspect
@Component
public class LoggingAspect {

    @Pointcut("execution(* com.example.service.*.*(..))")
    public void serviceLayer() {}

    @Before("serviceLayer()")
    public void logBefore(JoinPoint jp) {
        log.info("Entering: {}", jp.getSignature());
    }

    @Around("@annotation(com.example.Timed)")
    public Object logExecutionTime(ProceedingJoinPoint pjp) throws Throwable {
        long start = System.nanoTime();
        try {
            return pjp.proceed(); // must call this, or the target method NEVER executes!
        } finally {
            log.info("{} took {}ms", pjp.getSignature(), (System.nanoTime()-start)/1_000_000);
        }
    }
}
```

**Advice types:** @Before, @AfterReturning, @AfterThrowing, @After (finally-like), @Around (most powerful — full control, can short-circuit, modify return value, swallow exceptions).

**Q:** "What's the danger of forgetting pjp.proceed() in an @Around advice?"

The target method body silently never executes — no exception, no obvious error, just missing behavior. Classic debugging nightmare — always a good "describe a bug you've hit" interview story if you have one.

**Q:** "Multiple aspects on the same join point — how is ordering controlled?"

@Order annotation (lower value = higher precedence, runs first on the way "in" for @Before-style, last on the way "out"). Important for layering concerns correctly (e.g., security check must run before logging/transaction advice in most designs).

**PART D:** Spring Boot Auto-Configuration — the "magic" explained  
How @SpringBootApplication actually works

### It's a meta-annotation bundling

java

```java
@SpringBootConfiguration  // = @Configuration
@EnableAutoConfiguration  // the real magic
@ComponentScan            // scans current package + sub-packages
```

### @EnableAutoConfiguration mechanics

Spring Boot scans META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports (older versions: spring.factories) on the classpath of every JAR dependency.  
Loads a huge list of @Configuration classes (e.g., DataSourceAutoConfiguration, KafkaAutoConfiguration, RedisAutoConfiguration).

### Each auto-config class is guarded by conditional annotations

@ConditionalOnClass — only activate if a specific class is on the classpath (e.g., only configure Kafka beans if KafkaTemplate.class exists).  
@ConditionalOnMissingBean — only activate if the user hasn't already defined their own bean of that type (lets you override any auto-config simply by defining your own @Bean).  
@ConditionalOnProperty — only activate based on a property value (e.g., spring.kafka.enabled=true).  
@ConditionalOnWebApplication / @ConditionalOnBean etc.  
**Q:** "You added a dependency but your custom @Bean isn't being picked up / is being overridden. What's happening?"

Likely an ordering issue — your own @Configuration class might be processed after the auto-configuration due to @AutoConfigureAfter/@AutoConfigureBefore ordering, or you're missing @ConditionalOnMissingBean understanding (the auto-config bean might be defined with a different bean name, so both coexist, causing ambiguity — NoUniqueBeanDefinitionException). Debug via --debug flag or actuator's /actuator/conditions endpoint, which shows exactly which auto-configs were applied/excluded and why.

application.properties/yml — property resolution order (ask this to show config mastery)  
Highest to lowest precedence (partial, most relevant ones):

Command-line arguments (--server.port=8081)  
SPRING_APPLICATION_JSON env var  
JNDI attributes  
Java System properties (-Dserver.port=8081)  
OS environment variables  
application-{profile}.yml (profile-specific, outside jar)  
application.yml (outside jar)  
application-{profile}.yml (profile-specific, inside jar)  
application.yml (inside jar, packaged)  
@PropertySource annotations  
Default properties

### Profiles

```java
@Profile("prod")
@Bean
public DataSource prodDataSource() { ... }
```

```yaml
spring:
  config:
    activate:
      on-profile: prod
```

**PART E:** Spring Boot Actuator & Production-Readiness

### Key endpoints

```java
@Component
public class DownstreamHealthIndicator implements HealthIndicator {
    public Health health() {
        return isDownstreamUp() ? Health.up().build()
                                 : Health.down().withDetail("reason", "timeout").build();
    }
}
```

**PART F:** Exception Handling & Validation

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(ResourceNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(new ErrorResponse(ex.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> errors = ex.getBindingResult().getFieldErrors().stream()
            .collect(Collectors.toMap(FieldError::getField, FieldError::getDefaultMessage));
        return ResponseEntity.badRequest().body(errors);
    }
}
```

java

```java
public record CreateUserRequest(
    @NotBlank @Size(max = 50) String name,
    @Email String email,
    @Min(18) int age
) {}

@PostMapping("/users")
public ResponseEntity<User> create(@Valid @RequestBody CreateUserRequest req) { ... }
```

**Q:** "@Valid vs @Validated — what's the real difference?"

@Valid is standard Bean Validation (JSR-380), triggers validation, works for nested object graphs. @Validated is a Spring-specific variant that adds group-based validation support (@Validated(CreateGroup.class)) and — critically — is what enables method-level validation on non-controller beans (e.g., validating @Service method parameters via AOP, since @Valid alone on a plain @Service method parameter does nothing without @Validated at the class level to trigger the validation proxy).

**PART G:** Spring Boot Startup — What Actually Happens  
SpringApplication.run() creates a ConfigurableApplicationContext (type depends on classpath: AnnotationConfigServletWebServerApplicationContext for a servlet web app, reactive variant for WebFlux, plain for non-web).  
Prepares the Environment (profiles, property sources resolved).  
Runs ApplicationContextInitializers.  
Loads bean definitions (component scan + auto-configuration conditional evaluation).  
Instantiates and wires all singleton, non-lazy beans (this is where most startup time goes — DB connection pool init, Kafka consumer group join, etc.).  
Starts embedded servlet container (Tomcat/Jetty/Undertow) last (so it only starts accepting traffic once the context is mostly ready) — though note readiness vs this nuance is a known complexity in rolling deployments.  
Runs CommandLineRunner/ApplicationRunner beans.  
Publishes ApplicationReadyEvent.  
**Q:** "How would you speed up a slow-starting Spring Boot app (e.g., for faster Kubernetes rollouts / local dev loops)?"

Lazy initialization (spring.main.lazy-initialization=true) — beans created on first use, not eagerly at startup (tradeoff: shifts cost to first request, hides startup errors until later).  
Reduce component-scan scope / unnecessary auto-configurations (@SpringBootApplication(exclude = {...})).  
Use Spring Boot's build-time AOT processing + GraalVM native image (Spring Boot 3+) — compiles ahead-of-time, near-instant startup (ms instead of seconds), ideal for serverless/Cloud Run-style scale-to-zero workloads — very relevant talking point if GCP Cloud Run comes up.  
Profile with --debug or spring.boot.admin startup-time breakdown / ApplicationStartup API to find the slowest beans.  
**PART H:** @Transactional Deep Dive (bridges into next topic — JPA/Hibernate)

### Propagation types (classic matrix question)

| PROPAGATION | BEHAVIOR |
|---|---|
| REQUIRED (default) | Join existing transaction, or create new if none exists |
| REQUIRES_NEW | Always suspend current tx (if any) and start a brand new independent one |
| NESTED | Creates a savepoint within the existing tx — rollback only unwinds to the savepoint |
| SUPPORTS | Join if exists, else run non-transactionally |
| MANDATORY | Must run within an existing tx, else throws exception |
| NEVER / NOT_SUPPORTED | Must NOT run in a tx / suspends any existing tx |

**Q:** "When would you use REQUIRES_NEW? Give a real scenario."

**Audit logging:** you want the audit record to be committed even if the main business transaction rolls back (e.g., logging a failed payment attempt). Since REQUIRES_NEW suspends the outer transaction and commits independently, the audit log survives regardless of the outer transaction's fate.

**Q:** "Default rollback behavior — what triggers automatic rollback, and the classic gotcha?"

By default, Spring only rolls back on unchecked exceptions (RuntimeException/Error), not checked exceptions! If you throw a checked Exception inside a @Transactional method, the transaction commits anyway unless you explicitly configure @Transactional(rollbackFor = Exception.class). This trips up a huge number of developers who assume "any exception rolls back."

Isolation levels (tie directly into next topic on Hibernate/DB):  
READ_UNCOMMITTED → READ_COMMITTED (most DB defaults, e.g. Postgres) → REPEATABLE_READ (MySQL InnoDB default) → SERIALIZABLE.

🎯 Quick-Fire Quiz — Topic 3  
Why does field injection make unit testing harder, concretely (what has to change in your test code)?  
You inject a prototype-scoped bean into a singleton bean via plain @Autowired — what's wrong, and name 2 fixes.  
Explain exactly why this.someTransactionalMethod() called from within the same class silently skips the transaction.  
CGLIB vs JDK dynamic proxy — what 2 structural requirements does CGLIB impose on your class/methods?  
A checked exception is thrown inside a @Transactional method with default settings — does it roll back? Why/why not?  
What's the practical production difference between a failing liveness probe and a failing readiness probe on Kubernetes?  
How does @ConditionalOnMissingBean let you override Spring Boot's auto-configured beans without any XML or exclude annotations?  
Why would REQUIRES_NEW be the right propagation choice for writing an audit log entry, specifically?

If customer is @ManyToOne(fetch = FetchType.LAZY) (or even EAGER — doesn't fundamentally prevent N+1 unless you also fetch-join), each access triggers a separate SELECT to load that specific customer — 1 query for orders + N queries for each order's customer = N+1 total round trips to the DB.

Why does it still happen even with FetchType.EAGER?

FetchType.EAGER only means "load it immediately as part of initializing the entity," but Hibernate by default still issues it as a secondary SELECT per entity unless you explicitly request a JOIN FETCH or configure @Fetch(FetchMode.JOIN). EAGER controls when (immediately vs on-demand), not how (same query vs separate query) — this distinction trips up a lot of people and is a great thing to clarify in an interview to show depth.

Fixes (know all of these — interviewers love asking "name 3 ways to fix N+1"):

### JOIN FETCH in JPQL

```java
@Query("SELECT o FROM Order o JOIN FETCH o.customer")
List<Order> findAllWithCustomer();
```

Entity Graphs (more flexible, reusable, works with derived query methods):

```java
@EntityGraph(attributePaths = {"customer", "lineItems"})
List<Order> findAll();
```

@BatchSize (Hibernate-specific) — instead of N individual queries, batches them into WHERE id IN (?, ?, ?...) chunks:

```java
@BatchSize(size = 20)
@ManyToOne(fetch = FetchType.LAZY)
private Customer customer;
```

**Also settable globally:** hibernate.default_batch_fetch_size=20

"Why is JOIN FETCH dangerous when fetching multiple collections at once?"

Fetching two List-type collections via JOIN FETCH in the same query causes a Cartesian product (MultipleBagFetchException in Hibernate, or silently duplicated rows) — e.g., an Order with 3 line items and 2 tags would produce 6 rows, and Hibernate has to de-duplicate in memory. Fix: use a Set instead of List (still only fixes one collection safely — fetch at most one collection eagerly per query; fetch the second with a separate query/batch fetch, or use @BatchSize.

lazy does not fix the issue, it's just provide data on demand or immediate but internally still N+1 so batchsize is good option as join fetch will send duplicate , cartesian data , adding more n unnecessary data to in network.

Many engineers assume everything defaults to LAZY — it doesn't. @ManyToOne/@OneToOne default to EAGER, which is a very common source of accidental N+1 and over-fetching in production. Best practice: explicitly set FetchType.LAZY everywhere, and use JOIN FETCH/EntityGraph deliberately when you need eager loading for a specific use case.

**PART D:** Caching Layers

1. First-Level Cache (Persistence Context / Session cache)

Always on, cannot be disabled, scoped to a single EntityManager/transaction.  
**Guarantees:** within one transaction, calling find(Order.class, 1L) twice returns the same object reference, and only issues one SQL query (second call is a cache hit).

2. Second-Level Cache

Opt-in, shared across sessions/transactions (application-wide), requires a cache provider (Ehcache, Caffeine, Infinispan, Hazelcast via JCache/JSR-107).

```java
@Entity
@Cacheable
```

@org.hibernate.annotations.Cache(usage = CacheConcurrencyStrategy.READ_WRITE)

```java
public class Product { ... }
```

"Why is the 2nd-level cache dangerous/discouraged in a microservices/multi-instance deployment without a distributed cache backend?"

If each service instance has its own local (in-JVM) 2nd-level cache (e.g., Ehcache default), and another instance (or another service entirely writing to the same DB) updates a row, your instance's cache goes stale — no invalidation happens across instances. You'd need a distributed cache backend (e.g., Hazelcast, or push invalidation via Redis pub/sub) to make 2nd-level cache safe at scale. This is exactly the kind of "have you actually run this in production" question senior interviews probe — and ties directly into your Redis/Memorystore experience as a strong talking point.

Why do most senior engineers explicitly set spring.jpa.open-in-view=false in production?"  
OSIV is a crutch that hides N+1 problems (they happen silently during view rendering/serialization instead of being obvious in the service layer), holds DB connections open for the entire request duration (including template rendering, external API calls, etc.) — starving the connection pool under load — and makes performance bugs very hard to trace since the extra queries don't appear where you're looking. Turning it off forces you to be explicit about fetching, which is more work upfront but far more predictable and scalable in production.

**One final senior-engineer insight:** Disabling OSIV does not magically eliminate N+1 queries. You can still have N+1 inside your @Transactional service method. What disabling OSIV does is make the persistence boundary explicit, so you can control fetching and identify unexpected lazy loading much more easily.

That's why I would consider spring.jpa.open-in-view=false a sensible production default.

DTO best approach - minimum data transfer and no duplication

@Query("""

- SELECT new com.shop.dto.OrderSummary(
    - o.id,
    - c.name,
    - o.status

```java
    )
    FROM Order o
    JOIN o.customer c
    """)
List<OrderSummary> findOrderSummaries();
```

### generated sql

```java
SELECT o.id,c.name,o.status FROM orders o JOIN customer c ON c.id = o.customer_id;
```

4 ways for N+1 problem fix

1. Fetch join (but cartesian product and unnecessary duplicate data in network)
2. EntityGraph provide child and parent
3. Batch size (so limit data movement - global variable set so no need to put on every entity)
4. DTO approach as above (best among them)
5. sub select (like get ids then use in query)

```java
@OneToMany(mappedBy = "order", fetch = FetchType.LAZY)
@Fetch(FetchMode.SUBSELECT)
private List<OrderItem> items;
```

SELECT \*  
FROM order_item  
WHERE order_id IN (

- SELECT id FROM orders

```java
);
```

Technique                Best use case                Query behavior

| JOIN FETCH | Required relationships | Usually one joined query |
|---|---|---|
| @EntityGraph | Flexible fetch plans | Depends on fetch plan |
| @BatchSize | Lazy collections | Groups queries |
| DTO Projection | Read-heavy APIs | Select only required columns |
| SUBSELECT | Multiple parent collections | One collection-loading query per batch/subselect |

```java
public interface OrderRepository extends JpaRepository<Order, Long> {

    // 1. Derived query methods - parsed from method name
    List<Order> findByCustomerEmailAndStatusOrderByCreatedAtDesc(String email, OrderStatus status);

    // 2. JPQL
    @Query("SELECT o FROM Order o WHERE o.total > :minTotal")
    List<Order> findHighValueOrders(@Param("minTotal") BigDecimal minTotal);

    // 3. Native SQL
    @Query(value = "SELECT * FROM orders WHERE created_at > NOW() - INTERVAL '7 days'", nativeQuery = true)
    List<Order> findRecentOrders();

    // 4. Modifying query - needs @Modifying + @Transactional
    @Modifying
    @Query("UPDATE Order o SET o.status = :status WHERE o.id = :id")
    int updateStatus(@Param("id") Long id, @Param("status") OrderStatus status);

    // 5. Specification (dynamic/criteria-based queries)
    // 6. Projections (interface-based or DTO/record-based)
}
```

### Pagination

```java
Page<Order> findByStatus(OrderStatus status, Pageable pageable);
// Pageable pageable = PageRequest.of(0, 20, Sort.by("createdAt").descending());
```

**Q:** "You set batch_size=50 but Hibernate still issues individual INSERT statements. Why?"

**Classic gotcha:** if your entity uses GenerationType.IDENTITY for its @Id (auto-increment relying on the DB to generate the key), Hibernate cannot batch inserts — it needs the generated ID back immediately after each insert (to use in cascade/relationship management), forcing one-by-one execution. Fix: use GenerationType.SEQUENCE (with a pooled/allocationSize optimizer) instead, which lets Hibernate pre-allocate a batch of IDs client-side and then truly batch the inserts.

```java
@Transactional
public void transferMoney() {
```

- Account account = accountRepository.findById(1L)

```java
.orElseThrow();
```

- account.setBalance(500); (update trigger due to object changed and dirty check found so hibernate will try to reconsile the state with db)

```java
    entityManager.flush();

    // UPDATE already executed!

    throw new RuntimeException("Transfer failed");
}
```

**Dirty Checking:** Hibernate tracks changes to managed entities without requiring save().

**Automatic Flush:** Hibernate can execute SQL before commit, especially before queries affected by pending changes.

**Transaction Commit:** Makes the changes durable; flush alone does not.
