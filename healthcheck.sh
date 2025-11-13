#!/bin/bash

#HealthCheck Script for FastAPI Application
# This script verifies that the FastAPI application is running and healthy

set -e

echo "=========================================="
echo "Starting Health Check for FastAPI App"
echo "=========================================="

# Configuration
MAX_RETRIES=30
RETRY_INTERVAL=2
CONTAINER_NAME="fastapi-hello-world"
HEALTH_URL="http://localhost:8000/health"
HELLO_URL="http://localhost:8000/hello-world"

# Function to check if container is running
check_container() {
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "✓ Container '${CONTAINER_NAME}' is running"
        return 0
    else
        echo "✗ Container '${CONTAINER_NAME}' is not running"
        return 1
    fi
}

# Function to check health endpoint
check_health_endpoint() {
    local response=$(curl -s -o /dev/null -w "%{http_code}" ${HEALTH_URL} 2>/dev/null || echo "000")
    
    if [ "$response" = "200" ]; then
        echo "✓ Health endpoint is responding (HTTP $response)"
        return 0
    else
        echo "✗ Health endpoint not responding (HTTP $response)"
        return 1
    fi
}

# Function to test hello-world endpoint
test_hello_world() {
    echo ""
    echo "Testing /hello-world endpoint..."
    local response=$(curl -s ${HELLO_URL} 2>/dev/null || echo "")
    
    if echo "$response" | grep -q "Hello World"; then
        echo "✓ Hello World endpoint working correctly"
        echo "  Response: $response"
        return 0
    else
        echo "✗ Hello World endpoint not working"
        return 1
    fi
}

# Function to check container health status
check_container_health() {
    local health_status=$(docker inspect --format='{{.State.Health.Status}}' ${CONTAINER_NAME} 2>/dev/null || echo "none")
    
    if [ "$health_status" = "healthy" ]; then
        echo "✓ Container health status: healthy"
        return 0
    elif [ "$health_status" = "none" ]; then
        echo "⚠ Container has no health check configured"
        return 0
    else
        echo "✗ Container health status: $health_status"
        return 1
    fi
}

# Main health check logic
main() {
    local retry_count=0
    
    # Check if container is running
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if check_container; then
            break
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $MAX_RETRIES ]; then
            echo "Waiting for container to start... (Attempt $retry_count/$MAX_RETRIES)"
            sleep $RETRY_INTERVAL
        fi
    done
    
    if [ $retry_count -eq $MAX_RETRIES ]; then
        echo ""
        echo "=========================================="
        echo "HEALTH CHECK FAILED: Container not running"
        echo "=========================================="
        exit 1
    fi
    
    echo ""
    echo "Waiting for application to be ready..."
    retry_count=0
    
    # Check health endpoint
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if check_health_endpoint; then
            break
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $MAX_RETRIES ]; then
            echo "Waiting for health endpoint... (Attempt $retry_count/$MAX_RETRIES)"
            sleep $RETRY_INTERVAL
        fi
    done
    
    if [ $retry_count -eq $MAX_RETRIES ]; then
        echo ""
        echo "=========================================="
        echo "HEALTH CHECK FAILED: Health endpoint not responding"
        echo "=========================================="
        docker logs ${CONTAINER_NAME} --tail 20
        exit 1
    fi
    
    # Check container health status
    echo ""
    check_container_health
    
    # Test hello-world endpoint
    test_hello_world
    
    # Show container logs (last 10 lines)
    echo ""
    echo "=========================================="
    echo "Recent Container Logs:"
    echo "=========================================="
    docker logs ${CONTAINER_NAME} --tail 10
    
    echo ""
    echo "=========================================="
    echo "HEALTH CHECK PASSED: All systems operational"
    echo "=========================================="
    echo ""
    echo "Application URLs:"
    echo "  - Health: ${HEALTH_URL}"
    echo "  - Hello World: ${HELLO_URL}"
    echo ""
}

# Run main function
main