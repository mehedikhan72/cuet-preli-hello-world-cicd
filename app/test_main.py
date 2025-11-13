import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_hello_world_endpoint():
    """Test that hello-world endpoint returns correct response"""
    response = client.get("/hello-world")
    assert response.status_code == 200
    assert response.json() == {"message": "Hello World"}

def test_health_endpoint():
    """Test health endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}