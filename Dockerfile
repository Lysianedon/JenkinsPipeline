# Étape 1: Build de l'application
# Utilisation d'une image Maven avec JDK 17
FROM maven:3.9.6-eclipse-temurin-17 as builder

# Définition du répertoire de travail
WORKDIR /build

# Copie du fichier pom.xml pour télécharger les dépendances
COPY pom.xml .

# Téléchargement des dépendances Maven (mise en cache des layers Docker)
RUN mvn dependency:go-offline

# Copie des sources
COPY src src

# Build de l'application
RUN mvn package -DskipTests

# Étape 2: Image finale
FROM eclipse-temurin:17-jre-jammy

# Métadonnées de l'image
LABEL maintainer="CasuleCorp" \
      description="Jenkins Pipeline Java Application"

# Définition du répertoire de travail
WORKDIR /app

# Copie du JAR depuis l'étape de build
COPY --from=builder /build/target/*.jar app.jar

# Port exposé par l'application
EXPOSE 8080

# Variables d'environnement Java
ENV JAVA_OPTS="-Xmx512m -Xms256m"

# Point d'entrée pour l'application
ENTRYPOINT ["java", "-jar", "app.jar"]
