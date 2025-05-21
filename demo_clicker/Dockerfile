FROM eclipse-temurin:21

WORKDIR /app

COPY target/demo_clicker-0.0.1-SNAPSHOT.jar app.jar

RUN chmod 400 app.jar && \
    addgroup --system --gid 999 appgroup && \
    adduser --system --uid 999 --ingroup appgroup appuser && \
    chown appuser:appgroup app.jar
USER appuser

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
