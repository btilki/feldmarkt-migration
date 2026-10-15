FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /src
COPY pom.xml .
COPY src ./src
RUN mvn -q -DskipTests package

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /src/target/storefront-*.jar /app/storefront.jar
EXPOSE 8080
USER 65532
ENTRYPOINT ["java", "-jar", "/app/storefront.jar"]
