# Generic HTTP Token

**CORS:** (Cross-Origin Resource Sharing)  
The backend grants permission by returning specific HTTP response headers—most notably Access-Control-Allow-Origin, Access-Control-Allow-Methods, and Access-Control-Allow-Headers—that the browser checks before allowing the UI to read the server response

The Browser's Question (The OPTIONS Preflight) - Which tells what browsers wants to do and if it's allowed or not

so CORS filter should be before JWT filter otherwise OPTIONS request will give 401 as JWT token not available

## JWT

1. Header (Alg type RSA256, HS256),
2. Payload (user info, roles, expire etc) and
3. Signature

encoded_data = base64UrlEncode(header) + "." + base64UrlEncode(payload)  
signature = Sign(privateKey, encoded_data) OR  
signature = HMACSHA256(encoded_data, secret)

### Verification

1. By PublicKey (Asymetric Algo) --> Pass the jwt token to okta using public key path (RS256 (RSA Signature with SHA-256)
2. By Secret (Symmetric Algo) --> Use secret to verify signature (HS256 (HMAC with SHA-256))

application.yaml  
(Asymmetic RSA SHA 256  pub-private)

```yaml
spring.security.oauth2.resourceserver.issuer-uri: https://<your-okta-domain>/oauth2/default
```

(symmetic HMAC SHA 256  secret-secret)

```yaml
spring.security.oauth2.resourceserver.jwt.secret-key: mySuperSecretKey12345 # Your shared secret
```

OR

```bash
export SPRING_SECURITY_OAUTH2_RESOURCE_SERVER_JWT_SECRET-KEY=mySuperSecretKey12345
```

```java
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .authorizeRequests(authorize -> authorize
                .antMatchers("/public/**").permitAll()
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2.jwt()); // Enable JWT validation
        return http.build();
    }
}

@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .authorizeRequests(authorize -> authorize
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt
                    .jwsKeySupplier(() -> "mySuperSecretKey12345" //or get from gcp secret manager)
                )
            );
        return http.build();
    }
}
```
