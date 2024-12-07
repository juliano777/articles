# Podman =====================================================================

# Create a new network to be used by containers
podman network create --driver bridge net_pg

# Create a Postgres container
podman container run -itd \
    --name pg \
    --hostname pg.local \
    --network net_pg \
    -e POSTGRES_PASSWORD=123 \
    -p 5432:5432 \
    docker.io/library/postgres

# Docker =====================================================================

# Create a new network to be used by containers
docker network create --driver bridge net_pg

# Create a Postgres container
docker container run -itd \
        --name pg \
    --hostname pg.local \
    --network net_pg \
        -e POSTGRES_PASSWORD=123 \
        -p 5432:5432 \
        postgres
