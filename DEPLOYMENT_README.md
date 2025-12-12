# Shield AI Backend Deployment to Render

## Prerequisites

1. **GitHub Repository**: Code must be pushed to GitHub
2. **Render Account**: Sign up at [render.com](https://render.com)
3. **API Keys**: Obtain the following API keys:
   - OpenRouter API Key
   - Bing Search API Key

## Environment Variables Required

Set these in your Render dashboard after deployment:

### Required API Keys
- `OPENROUTER_API_KEY`: Your OpenRouter API key for AI chat functionality
- `BING_SEARCH_API_KEY`: Your Bing Search API key for job search functionality

### Auto-Configured by Render
- `DATABASE_URL`: PostgreSQL connection string (auto-configured)
- `REDIS_URL`: Redis connection string (auto-configured)
- `SECRET_KEY`: Auto-generated secret key
- `JWT_SECRET_KEY`: Auto-generated JWT secret

## Deployment Steps

### 1. Connect GitHub Repository
1. Go to [render.com](https://render.com) and sign in
2. Click "New +" → "Web Service"
3. Connect your GitHub account and select the `Shield-ai` repository

### 2. Configure Web Service
- **Name**: `shield-ai-backend`
- **Runtime**: `Python 3`
- **Build Command**: `pip install -r backend/requirements.txt`
- **Start Command**: `gunicorn --chdir backend --workers 2 --threads 2 --bind 0.0.0.0:$PORT wsgi:app`

### 3. Configure Database
1. Create a new PostgreSQL database in Render
2. Name it: `shield_ai_db`
3. Plan: Starter (free tier)
4. The `DATABASE_URL` will be automatically configured

### 4. Configure Redis (Optional but Recommended)
1. Create a new Redis instance in Render
2. Name it: `shield-ai-redis`
3. Plan: Starter (free tier)
4. The `REDIS_URL` will be automatically configured for rate limiting

### 5. Set Environment Variables
In your web service settings, add these environment variables:

| Key | Value | Description |
|-----|-------|-------------|
| `FLASK_ENV` | `production` | Flask environment |
| `CORS_ORIGINS` | `https://shieldai.ke` | Allowed CORS origins |
| `LOG_LEVEL` | `INFO` | Logging level |
| `OPENROUTER_API_KEY` | `[Your API Key]` | OpenRouter API key |
| `BING_SEARCH_API_KEY` | `[Your API Key]` | Bing Search API key |

### 6. Deploy
1. Click "Create Web Service"
2. Render will automatically build and deploy your application
3. Monitor the build logs for any issues

## Post-Deployment Steps

### Database Migration
After deployment, run database migrations:

```bash
# Via Render shell or SSH
cd backend
flask db upgrade
```

### Health Check
Test your deployment:
```bash
curl https://your-render-app-url.onrender.com/api/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2024-...",
  "version": "1.0.0"
}
```

## Troubleshooting

### Common Issues

1. **Build Fails**: Check the build logs for missing dependencies
2. **Database Connection**: Ensure PostgreSQL database is properly linked
3. **Environment Variables**: Verify all required API keys are set
4. **CORS Issues**: Ensure `CORS_ORIGINS` includes your frontend domain

### Logs
- View application logs in Render dashboard
- Check `/logs/app.log` for detailed application logs

## Production URLs

After deployment, your API will be available at:
- **Base URL**: `https://shield-ai-backend.onrender.com`
- **API Base**: `https://shield-ai-backend.onrender.com/api`
- **Health Check**: `https://shield-ai-backend.onrender.com/api/health`

## Security Notes

- All API keys are stored securely in Render's environment variables
- HTTPS is enforced in production
- CORS is restricted to allowed domains only
- Rate limiting is enabled with Redis storage
- Security headers are configured via Flask-Talisman

## Monitoring

- Monitor application performance in Render dashboard
- Set up alerts for downtime or errors
- Check Redis usage for rate limiting statistics
