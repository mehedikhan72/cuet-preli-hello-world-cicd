pipeline {
    agent any
    
    environment {
        IMAGE_NAME = 'fastapi-hello-world'
        IMAGE_TAG = "${BUILD_NUMBER}"
        CONTAINER_NAME = 'fastapi-hello-world'
    }
    
    stages {
        stage('Checkout') {
            steps {
                sh '''
                    echo 'Cloning repo...'
                    if [ ! -d ".git" ]; then
                        git clone https://github.com/mehedikhan72/cuet-preli-hello-world-cicd.git .
                    else
                        git pull origin master
                    fi
                    ls -la
                '''
            }
        }
                
        stage('Build') {
            steps {
                echo '=========================================='
                echo 'Stage: Build'
                echo '=========================================='
                script {
                    echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
                    sh """
                        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
                    """
                }
                echo '✓ Build completed successfully'
            }
        }
        
        stage('Test') {
            steps {
                echo '=========================================='
                echo 'Stage: Unit Tests'
                echo '=========================================='
                script {
                    echo 'Running unit tests...'
                    sh """
                        docker run --rm ${IMAGE_NAME}:${IMAGE_TAG} \
                        pytest test_main.py -v --tb=short
                    """
                }
                echo '✓ All tests passed'
            }
        }
        
        stage('Package') {
            steps {
                echo '=========================================='
                echo 'Stage: Package'
                echo '=========================================='
                script {
                    echo 'Docker image packaged and tagged:'
                    sh """
                        docker images | grep ${IMAGE_NAME}
                    """
                    echo "✓ Image ${IMAGE_NAME}:${IMAGE_TAG} ready for deployment"
                }
            }
        }
        
        stage('Deploy') {
            steps {
                echo '=========================================='
                echo 'Stage: Deploy'
                echo '=========================================='
                script {
                    echo 'Stopping and removing existing containers...'
                    sh """
                        docker compose down || true
                        docker rm -f ${CONTAINER_NAME} || true
                    """
                    
                    echo 'Deploying application with Docker Compose...'
                    sh """
                        docker compose up -d
                    """
                    
                    echo 'Waiting for container to start...'
                    sh 'sleep 5'
                    
                    echo '✓ Application deployed successfully'
                }
            }
        }
        
        stage('Health Check') {
            steps {
                echo '=========================================='
                echo 'Stage: Health Check'
                echo '=========================================='
                script {
                    echo 'Running health check script...'
                    sh """
                        chmod +x healthcheck.sh
                        ./healthcheck.sh
                    """
                    
                    echo ''
                    echo '=========================================='
                    echo 'Verifying /hello-world endpoint...'
                    echo '=========================================='
                    sh """
                        echo 'Calling /hello-world endpoint:'
                        curl -s http://localhost:8000/hello-world
                        echo ''
                    """
                    
                    echo '✓ Health check passed - Application is healthy'
                }
            }
        }
    }
    
    post {
        success {
            echo ''
            echo '=========================================='
            echo '🎉 PIPELINE SUCCESS 🎉'
            echo '=========================================='
            echo 'All stages completed successfully!'
            echo ''
            echo 'Application Status:'
            sh """
                echo '  Container Status:'
                docker ps | grep ${CONTAINER_NAME} || echo '  No container found'
                echo ''
                echo '  Application URLs:'
                echo '    - Health Check: http://localhost:8000/health'
                echo '    - Hello World:  http://localhost:8000/hello-world'
                echo ''
            """
        }
        
        failure {
            echo ''
            echo '=========================================='
            echo '❌ PIPELINE FAILED ❌'
            echo '=========================================='
            echo 'Pipeline execution failed. Check logs above.'
            echo ''
            sh """
                echo 'Container Logs:'
                docker logs ${CONTAINER_NAME} --tail 50 || echo 'No logs available'
            """
        }
        
        always {
            echo ''
            echo '=========================================='
            echo 'Cleanup (if needed)'
            echo '=========================================='
            echo 'Pipeline execution completed.'
            sh 'docker-compose down'
        }
    }
}