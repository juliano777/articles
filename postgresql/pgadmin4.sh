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

# Create a PgAdmin4 container
docker container run -itd -p 8080:80 \
    --name pgadmin4 \
    --hostname pgadmin4.local \
    --network net_pg \
    -e 'PGADMIN_DEFAULT_EMAIL=juliano777@gmail.com' \
    -e 'PGADMIN_DEFAULT_PASSWORD=123' \
    dpage/pgadmin4

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

# Create a PgAdmin4 container
podman container run -itd -p 8080:80 \
    --name pgadmin4 \
    --hostname pgadmin4.local \
    --network net_pg \
    -e 'PGADMIN_DEFAULT_EMAIL=juliano777@gmail.com' \
    -e 'PGADMIN_DEFAULT_PASSWORD=123' \
    docker.io/dpage/pgadmin4

