# KIND_case_study

## Developments steps:
### Phase 1: the app itself
- The app uses simple **RESTful api** and provides the bare-bones functionality.
- I could have built the app using python with flask which would have been faster and possibly even lighter. As the goal of the project was to showcase security features, I opted instead for **Java** with **Spring Boot** and **Spring Security**, as these are widely used in enterprise environments and provide excellent security out of the box. For example Spring Security give us a **log-in form** with **protection against SQL injections** and **defence against Cross-Site Request Forgery**. Were this a proper web application, and not a simple cookie-clicker, the spring framework would have made securing the web application much easier.
- Important to note here is that the app handles **CSRF tokens**. This is like a special stamp that only you and the legitimate website know about. For example if you're logged in your bank and visit a malicious site, that site could make your browser send a request to transfer money from your account. But since the attacker doesn't have the CSRF token, the request fails.

### Phase 2: dockerization
- The docker file goes through the standard process of [containerizing a springboot app](https://spring.io/guides/gs/spring-boot-docker)
- `docker build -t click-counter:v1 .` would build the image from the dockerfile
- `docker run -p 8080:8080 demo-clicker:v1` would run the container, making the app accessible on `http://localhost:8080/`
- The application is running with user privileges, which helps mitigate some risks such as container breakout attacks. Root users can do anything in the system, including modifying the filesystem, creating devices, etc. Non-root users can't bind to ports below 1024. Spring Boot uses port 8080 by default, which is fine. 
- The only thing the user will need is read access to the JAR file. This is accomplished with:
```
RUN chmod 400 app.jar && \
    addgroup --system --gid 999 appgroup && \
    adduser --system --uid 999 --ingroup appgroup appuser && \
    chown appuser:appgroup app.jar
USER appuser
```

- here is what happens:
    - 1) owner (initially root) can only read the file, group members and others have no permissions
    - 2) create a new system group for the container. The Group ID (and User ID) < 1000 is convention for system accounts.
    - 3) create a dedicated system user (no login and no home dir) with minimal privileges, makes the user a member of the appgroup. 
    - 4) give appuser and appgroup the ownership to the jar file
    - 5) set the default user for the container runtime. Without this, the container processes would run as root by default
    - Effect: 
        - Only appuser can read the file
        - No one (not even appuser) can write to or execute the file
        - No other users or processes can access the file at all

- Why are read permissions enough?

    When java -jar app.jar is called, the JVM:
    - Reads the JAR file content into memory
    - Extracts and loads the classes, resources, and metadata
    - Executes the code from memory
    - The JVM never needs to: Execute the JAR as a binary



## Tech stack

- Java, Maven, Spring Boot
- Docker, Kubernetes

## Sources
- https://spring.io/guides/gs/spring-boot-docker
