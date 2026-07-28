FROM vaultwarden/server:1.37.0

# Vaultwarden's web server (Rocket) doesn't read Railway's own PORT variable -
# it needs ROCKET_PORT specifically. Setting both explicitly (this file's ENV
# plus a matching Railway PORT variable) rather than relying on a Dockerfile
# default alone - a Dockerfile-only default was already proven insufficient
# for Railway's routing layer on another template in this project (Metabase).
ENV ROCKET_ADDRESS=0.0.0.0
ENV ROCKET_PORT=8080
ENV PORT=8080

EXPOSE 8080
