# ============================================
# Frontend Dockerfile
#
# Simple: copies static files into an nginx container.
# nginx serves the HTML/CSS/JS and proxies /api to the backend.
# ============================================

FROM nginx:1.27-alpine

# Remove default nginx page
RUN rm -rf /usr/share/nginx/html/*

# Copy our static files
COPY src/ /usr/share/nginx/html/

# Copy our nginx config
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# nginx runs on port 80
EXPOSE 80

# Start nginx in foreground (required for Docker)
CMD ["nginx", "-g", "daemon off;"]
