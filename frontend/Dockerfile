# ============================================
# Frontend Dockerfile
#
# Simple: copies static files into an nginx container.
# nginx serves the HTML/CSS/JS and proxies /api to the backend.
#
# In production, the entrypoint script generates the nginx config
# from a template, injecting the ORIGIN_VERIFY_SECRET for CloudFront
# origin verification. In local dev, default.conf is used directly.
# ============================================

FROM nginx:1.27-alpine

# Remove default nginx page
RUN rm -rf /usr/share/nginx/html/*

# Copy our static files
COPY src/ /usr/share/nginx/html/

# Copy nginx configs: default.conf for local dev, template for production
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY nginx/default.conf.template /etc/nginx/conf.d/default.conf.template

# Copy entrypoint script (generates config from template at startup)
COPY nginx/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# nginx runs on port 80
EXPOSE 80

# Start nginx in foreground (required for Docker)
CMD ["nginx", "-g", "daemon off;"]
