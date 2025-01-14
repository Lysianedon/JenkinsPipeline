pipeline {
    agent any

    // Définition des outils nécessaires
    tools {
        maven 'M3' // Assurez-vous que Maven est configuré dans Jenkins
        git 'Default'  // Utilisation de l'installation Git par défaut
    }

    environment {
        DOCKER_IMAGE = 'jenkinspipeline'
        DOCKER_TAG = "${BUILD_NUMBER}"
        ARTIFACTORY_REPO = 'localhost:8082'
        // Configuration Maven
        MAVEN_PROFILE = 'Pipeline-Test'
    }

    stages {
        stage('Checkout') {
            steps {
                // Nettoyage de l'espace de travail avant checkout
                cleanWs()
                checkout scm
            }
        }

        stage('Build') {
            steps {
                // Affichage des versions des outils
                sh '''
                    echo "Maven version:"
                    mvn --version
                    echo "Git version:"
                    git --version
                    echo "Docker version:"
                    docker --version
                '''
                
                script {
                    try {
                        // Build Maven avec le profile Pipeline-Test
                        sh "mvn clean package"
                        
                        // Build de l'image Docker
                        docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}", "-f Dockerfile .")
                    } catch (Exception e) {
                        echo "Erreur pendant le build: ${e.message}"
                        throw e
                    }
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    try {
                        // Exécution des tests avec Maven
                        sh "mvn test -P ${MAVEN_PROFILE}"
                    } catch (Exception e) {
                        echo "Erreur pendant les tests: ${e.message}"
                        throw e
                    }
                }
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    try {
                        withSonarQubeEnv(credentialsId: 'sonarqube-analysis', installationName: 'SonarQube') {
                            sh """
                                mvn clean verify sonar:sonar \
                                    -Dsonar.projectKey=JenkinsPipeline \
                                    -Dsonar.projectName='JenkinsPipeline' \
                                    -Dsonar.host.url=http://sonarqube:9000
                            """
                        }
                    } catch (Exception e) {
                        echo "Erreur pendant l'analyse SonarQube: ${e.message}"
                        echo "Étape ignorée - continuez le pipeline"
                    }
                }
            }
        }

        stage('Push to Artifactory') {
            steps {
                script {
                    try {
                        withCredentials([usernamePassword(
                            credentialsId: 'artifactory-credentials',
                            usernameVariable: 'ARTIFACTORY_USERNAME',
                            passwordVariable: 'ARTIFACTORY_PASSWORD'
                        )]) {
                            docker.withRegistry("http://${ARTIFACTORY_REPO}", 'artifactory-credentials') {
                                def appImage = docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}")
                                appImage.push()
                                appImage.push('latest')
                            }
                        }
                    } catch (Exception e) {
                        echo "Erreur pendant le push vers Artifactory: ${e.message}"
                        throw e
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    try {
                        sh """
                            docker stop ${DOCKER_IMAGE} || true
                            docker rm ${DOCKER_IMAGE} || true
                            docker run -d \
                                --name ${DOCKER_IMAGE} \
                                --network ci_network \
                                -p 8090:8080 \
                                ${ARTIFACTORY_REPO}/${DOCKER_IMAGE}:${DOCKER_TAG}
                        """
                    } catch (Exception e) {
                        echo "Erreur pendant le déploiement: ${e.message}"
                        throw e
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                cleanWs()
                sh 'docker system prune -f || true'
            }
        }
        success {
            echo 'Pipeline exécuté avec succès!'
        }
        failure {
            echo 'Le pipeline a échoué!'
        }
    }
}
