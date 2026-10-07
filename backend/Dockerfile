# Multi-stage per docker skill: builder (maven) -> layertools extract -> slim runtime, non-root.
# Stage 1: Build
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app
COPY pom.xml .
RUN apk add --no-cache maven && mvn dependency:go-offline -B
COPY src src
RUN mvn package -DskipTests -B

# Stage 2: Extract layered JAR for cache efficiency
RUN java -Djarmode=layertools -jar target/*.jar extract --destination extracted

# Stage 3: Runtime
FROM eclipse-temurin:21-jre-alpine
RUN addgroup -S app && adduser -S app -G app
USER app
WORKDIR /app
COPY --from=builder --chown=app:app /app/extracted/dependencies/ ./
COPY --from=builder --chown=app:app /app/extracted/spring-boot-loader/ ./
COPY --from=builder --chown=app:app /app/extracted/snapshot-dependencies/ ./
COPY --from=builder --chown=app:app /app/extracted/application/ ./
EXPOSE 8080
ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
