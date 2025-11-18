"""
Main routes module for Shield AI Backend

This module serves as the central routing configuration, importing and organizing
all API blueprints for the application.
"""

# Import blueprints directly
from .routes.api_routes import api_bp
from .routes.mpesa_routes import mpesa_bp
from .demo_controller import demo_bp

# Export all blueprints for easy importing
__all__ = ['api_bp', 'mpesa_bp', 'demo_bp']

# Blueprint documentation for API discovery
BLUEPRINTS = {
    'api_bp': {
        'blueprint': api_bp,
        'url_prefix': '/api',
        'description': 'Core API endpoints for authentication, users, and transactions'
    },
    'mpesa_bp': {
        'blueprint': mpesa_bp,
        'url_prefix': '/api',
        'description': 'M-Pesa payment integration endpoints'
    },
    'demo_bp': {
        'blueprint': demo_bp,
        'url_prefix': '/api',
        'description': 'Demo and testing endpoints'
    }
}