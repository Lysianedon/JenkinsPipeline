pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'jenkinspipeline'
        DOCKER_TAG = "${BUILD_NUMBER}"
        ARTIFACTORY_REPO = 'localhost:8082'
        ARTIFACTORY_CREDS = credentials('artifactory-credentials')
        // Configuration Maven
        MAVEN_PROFILE = 'Pipeline-Test'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                script {
                    // Build Maven avec le profile Pipeline-Test
                    sh "mvn clean package -P ${MAVEN_PROFILE}"
                    // Build de l'image Docker
                    docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}", "-f Dockerfile .")
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    // Exécution des tests avec Maven
                    sh "mvn test -P ${MAVEN_PROFILE}"
                }
            }
            post {
                always {
                    // Publication des résultats des tests JUnit
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    withSonarQubeEnv('SonarQube') {
                        // Analyse SonarQube avec le profile spécifique
                        sh "mvn sonar:sonar -P ${MAVEN_PROFILE}"
                    }
                }
            }
        }

        stage('Push to Artifactory') {
            steps {
                script {
                    docker.withRegistry("http://${ARTIFACTORY_REPO}", 'artifactory-credentials') {
                        def appImage = docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}")
                        appImage.push()
                        appImage.push('latest')
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    sh """
                        docker stop ${DOCKER_IMAGE} || true
                        docker rm ${DOCKER_IMAGE} || true
                        docker run -d \
                            --name ${DOCKER_IMAGE} \
                            --network ci_network \
                            -p 8090:8080 \
                            ${ARTIFACTORY_REPO}/${DOCKER_IMAGE}:${DOCKER_TAG}
                    """
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline exécuté avec succès!'
        }
        failure {
            echo 'Le pipeline a échoué!'
        }
    }
}
