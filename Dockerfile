# Use official Nginx image (not alpine, this is the full Debian-based one)
FROM nginx:latest

# Copy your index.html into nginx's default web root
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80 so ECS/ALB can route traffic
EXPOSE 80

# Use the default nginx start command
CMD ["nginx", "-g", "daemon off;"]

