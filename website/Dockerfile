# Stage 1: Serve static website with NGINX
FROM nginx:1.25.4-alpine

# Set working directory
WORKDIR /usr/share/nginx/html

# Copy website files from the website directory
COPY website/ /usr/share/nginx/html/

# Copy NGINX configuration (if you have one)
# COPY website/nginx.conf /etc/nginx/conf.d/default.conf

# Build metadata
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.description="FinanSecure Website - Static content served by NGINX"

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/index.html || exit 1

# Run NGINX in foreground
CMD ["nginx", "-g", "daemon off;"]
