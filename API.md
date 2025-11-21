<!-- sign in logic -->
For the user to login first run the backend =>
 Flask run/python run.py
 Ensure all the python packages/Dependencies are installed.
 All api callbacks for mpesa are included are as follows:
 localhost:5000
- `POST /api/stkpush` - Initiate STK Push payment,
- `POST /api/callback` - Handle M-Pesa payment callbacks,
- `GET /api/transactions/{id}` - Query specific transaction status,
- `GET /api/transactions?user_id={id}` - Get user's M-Pesa transactions 
The api call for the backend is pointing to the computers ip so it won't be poiting out to the itself 
that is `http://10.0.2.2:5000/api`
if this is pointing to: `http://localhost:5000/api` then it is wrong the flutter app might not recognize very well 

<!-- registration logic -->
What happens is when the use registers in the app then the credentials are pushed to the backend and then recorded in the sql query database schema @shield_dev.db
 The pin is hashed for enhanced security so that no one understands it but in real sense the user login 
 the credentials are recognized in the backend.
 To check for backend health type: `http://localhost:5000/api/health` 

