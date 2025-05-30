# About the project


![DevSecOps](./docs/devsecops.jpg)
![Defence](./docs/defence.jpg)
![Project layout](./docs/arch.jpg)


## How to deploy

1) clone the repo locally

2) make sure you have all the necessary tools (docker, terraform, etc)

3) Navigate to demo_clicker_present

4) Optionally generate the app jar with `mvn clean install`. This repo includes a pre-compiled jar. 

5) Go to deployment and run the *start.sh* script with the name of the env you want to set up. The allowed envs are 'dev', 'test' and 'prod'. The script will:
    
    - set up the desired env/workspace
    - initialize
    - prepare the docker image from the jar
    - set up the Infrastructure
    - deploy the application


6) After everything is ready you should be able to test the application at:
    
    - http://prod.localhost
    - http://test.localhost:8080
    - http://dev.localhost:7070




## Developments steps:
### Phase 1: the app itself
- The app uses simple **RESTful api** and provides the bare-bones functionality.
- I could have built the app using python with flask which would have been faster and possibly even lighter. As the goal of the project was to showcase security features, I opted instead for **Java** with **Spring Boot** and **Spring Security**, as these are widely used in enterprise environments and provide excellent security out of the box. For example Spring Security give us a **log-in form** with **protection against SQL injections** and **defence against Cross-Site Request Forgery**. Were this a proper web application, and not a simple cookie-clicker, the spring framework would have made securing the web application much easier.
- Important to note here is that the app handles **CSRF tokens**. This is like a special stamp that only you and the legitimate website know about. For example if you're logged in your bank and visit a malicious site, that site could make your browser send a request to transfer money from your account. But since the attacker doesn't have the CSRF token, the request fails.
- I have added custom endpoint that can be accessed without login to check application health. For that I've used the springboot actuator. It is running on a port separate from the actual application and is secured that the only information it provides is "UP" or "DOWN", minimizing risks.

### Phase 2: dockerization
- The docker file goes through the standard process of [containerizing a springboot app](https://spring.io/guides/gs/spring-boot-docker)
- `docker build -t click-counter:v1 .` would build the image from the dockerfile
- `docker run -p 8080:8080 demo-clicker:v1` would run the container, making the app accessible on `http://localhost:8080/`
- The application is running with user privileges, which helps mitigate some risks such as container breakout attacks. Root users can do anything in the system, including modifying the filesystem, creating devices, etc. Non-root users can't bind to ports below 1024. Spring Boot uses port 8080 by default, which is fine. 
- The only thing the user will need is read access to the JAR file. This is accomplished with:
```
RUN addgroup -S -g 998 appgroup && \
    adduser -S -u 998 -G appgroup appuser && \
    chown root:appgroup app.jar && \
    chmod 440 app.jar

USER 998
```

- here is what happens:
    - 1) create a new system group for the container. The Group ID (and User ID) < 1000 is convention for system accounts.
    - 2) create a dedicated system user (no login and no home dir) with minimal privileges, makes the user a member of the appgroup. 
    - 3) ensure the owner is root. Allow the appgroup members to access the file.
    - 4) set root and appgroup permissions to readonly. No permissions for anybody else
    - 5) set the default user for the container runtime. Without this, the container processes would run as root by default. We are giing the uid, so kubernetes can later validate that the user is not root.
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

- Originally *eclipse-temurin:21* was used as base image. While mostly okay, it provided bash, sudo, and other programs that are a) not needed and b) increase the attack surface. Using a distroless image and a seperate builder image was an overkill, I settled on suing the minimal *eclipse-temurin:21-jre-alpine* base image. This makes Lotl attacks more difficult.



### Phase 3: kubernetes + terraform
- Originally I used **minikube** for creating and running clusters locally (useful for testing before deploying in production). However since multi-node clusters are experimental and the assignment clearly prefered kind over minikube, I decided to use that.
Based on your Terraform configuration, here's the step-by-step process for building infrastructure and deploying the application:

#### Infrastructure Build Steps

1. **Create KIND Cluster** (`kind_cluster.tf`)
   - Creates a multi-node KIND cluster with control-plane and worker nodes
   - Sets up port mappings (80, 443) for ingress traffic
   - Generates kubeconfig at `~/.kube/config-{environment}`

2. **Install NGINX Ingress Controller** (`nginx_ingress.tf`)
   - Deploys NGINX ingress using Helm chart
   - Configures it with custom values from `nginx_ingress_values.yaml`
   - Waits for ingress controller pods to be ready

3. **Load Docker Image** (`kubernetes.tf`)
   - Loads the `demo-clicker:{image_tag}` Docker image into the KIND cluster

#### Application Deployment Steps

4. **Create Namespace**
   - Creates `demo-clicker-{environment}` namespace

5. **Deploy Application** 
   - Creates Kubernetes deployment with specified replica count 
   - Configures container with ports 8080 (app) and 8081 (management)
   - Sets resource limits/requests and security context
   - Configures health/readiness probes on management port
   - For example 'prod' gets more replicas with more ressources

6. **Create Services**
   - Main service: Exposes port 80 → 8080 for application traffic
   - Management service: Exposes port 8081 for health checks (cluster-internal)

7. **Setup Ingress**
   - Creates ingress rule routing `{environment}.localhost` to the main service
   - Uses NGINX ingress class

The system uses environment-specific `.tfvars` files to configure different resource allocations and replica counts for dev/test/prod environments.


    
### Phase 4: What remains

- HTTPS & cert management
- Enable Spring Security with login
- Secure namepaces and establish RBAC
- GitOps with ArgoCD


## Tech stack

- Java, Maven, Spring Boot
- Docker, Kubernetes (kubectl, kind)
- Terraform, Nginx

## Sources
- https://spring.io/guides/gs/spring-boot-docker
- https://registry.terraform.io/providers
- https://www.youtube.com/watch?v=Nm2c9xvGMpU
- https://kubernetes.io/docs/concepts/services-networking/ingress
- https://docs.nginx.com/nginx-ingress-controller/installation/installing-nic/installation-with-helm
