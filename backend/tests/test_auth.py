import unittest
import json
from uuid import uuid4

from app import create_app, db
from app.models import User


class AuthTestCase(unittest.TestCase):
    def setUp(self):
        """Set up a test environment."""
        self.app = create_app("testing")
        self.app_context = self.app.app_context()
        self.app_context.push()
        db.create_all()
        self.client = self.app.test_client()

        # Use a unique phone number for each test run to avoid conflicts
        self.user_phone = f"254{str(uuid4().int)[:9]}"
        self.user_pin = "1234"
        self.user_data = {
            "full_name": "Test User",
            "phone": self.user_phone,
            "pin": self.user_pin,
        }

    def tearDown(self):
        """Clean up the test environment."""
        db.session.remove()
        db.drop_all()
        self.app_context.pop()

    def test_1_register_user_success(self):
        """Test successful user registration."""
        response = self.client.post("/api/users", data=json.dumps(self.user_data), content_type="application/json")
        self.assertEqual(response.status_code, 201, "Registration failed with a non-201 status.")

        json_response = response.get_json()
        self.assertIn("id", json_response, "Response missing user ID.")
        self.assertEqual(json_response["phone"], self.user_phone, "Response phone does not match.")
        
        # Verify user is in the database
        user = User.query.filter_by(phone=self.user_phone).first()
        self.assertIsNotNone(user, "User was not saved to the database.")
        self.assertTrue(user.check_pin(self.user_pin), "PIN was not stored correctly.")

    def test_2_register_user_conflict(self):
        """Test registering a user that already exists."""
        # First, create the user
        self.client.post("/api/users", data=json.dumps(self.user_data), content_type="application/json")
        
        # Then, try to create the same user again
        response = self.client.post("/api/users", data=json.dumps(self.user_data), content_type="application/json")
        self.assertEqual(response.status_code, 409, "Did not return 409 on duplicate registration.")

    def test_3_login_user_success(self):
        """Test successful user login."""
        # First, create the user
        self.client.post("/api/users", data=json.dumps(self.user_data), content_type="application/json")
        
        login_data = {"phone": self.user_phone, "pin": self.user_pin}
        response = self.client.post("/api/login", data=json.dumps(login_data), content_type="application/json")
        self.assertEqual(response.status_code, 200, "Login failed with correct credentials.")
        
        json_response = response.get_json()
        self.assertEqual(json_response["phone"], self.user_phone, "Logged in user data is incorrect.")

    def test_4_login_invalid_pin(self):
        """Test login with an invalid PIN."""
        # First, create the user
        self.client.post("/api/users", data=json.dumps(self.user_data), content_type="application/json")

        login_data = {"phone": self.user_phone, "pin": "4321"}  # Incorrect PIN
        response = self.client.post("/api/login", data=json.dumps(login_data), content_type="application/json")
        self.assertEqual(response.status_code, 401, "Did not return 401 on invalid PIN.")

    def test_5_login_user_not_found(self):
        """Test login with a non-existent user."""
        login_data = {"phone": "254000000000", "pin": "1234"}
        response = self.client.post("/api/login", data=json.dumps(login_data), content_type="application/json")
        self.assertEqual(response.status_code, 404, "Did not return 404 for non-existent user.")


if __name__ == "__main__":
    unittest.main()
