# Étape 1: Build de l'application
# Utilisation d'une image Maven avec JDK 8
FROM maven:3.8-jdk-8 as builder

# Définition du répertoire de travail
WORKDIR /build

# Copie du fichier pom.xml pour télécharger les dépendances
COPY pom.xml .

# Téléchargement des dépendances Maven (mise en cache des layers Docker)
RUN mvn dependency:go-offline

# Copie des sources
COPY src src

# Build de l'application avec le profile Pipeline-Test
RUN mvn package -DskipTests

# Étape 2: Image finale
# Utilisation d'une image JRE 8 minimale pour l'exécution
FROM openjdk:8-jre-slim

# Métadonnées de l'image
LABEL maintainer="CasuleCorp" \
      description="Jenkins Pipeline Java Application"

# Définition du répertoire de travail
WORKDIR /app

# Copie du JAR depuis l'étape de build
COPY --from=builder /build/target/JenkinsPipeline-1.0.jar app.jar

# Port exposé par l'application
EXPOSE 8080

# Configuration des variables d'environnement Java
ENV JAVA_OPTS="-Xmx512m -Xms256m"

ENTRYPOINT ["java", "-jar", "app.jar"]
