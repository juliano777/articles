# Podman =====================================================================

# Create a new network to be used by containers
podman network create --driver bridge net_pg

# Create a PgAdmin4 container
podman container run -itd -p 8080:80 \
    --name pgadmin4 \
    --hostname pgadmin4.local \
    --network net_pg \
    -e 'PGADMIN_DEFAULT_EMAIL=juliano777@gmail.com' \
    -e 'PGADMIN_DEFAULT_PASSWORD=123' \
    docker.io/dpage/pgadmin4

# Docker =====================================================================

# Create a new network to be used by containers
docker network create --driver bridge net_pg

# Create a PgAdmin4 container
docker container run -itd -p 8080:80 \
    --name pgadmin4 \
    --hostname pgadmin4.local \
    --network net_pg \
    -e 'PGADMIN_DEFAULT_EMAIL=juliano777@gmail.com' \
    -e 'PGADMIN_DEFAULT_PASSWORD=123' \
    dpage/pgadmin4

