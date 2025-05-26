FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

COPY target/demo_clicker-0.0.1-SNAPSHOT.jar app.jar

RUN addgroup -S -g 998 appgroup && \
    adduser -S -u 998 -G appgroup appuser && \
    chown root:appgroup app.jar && \
    chmod 440 app.jar

USER 998

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
