# Jupyter Podman container
podman run -itd  \
    --name jupyter \
    --hostname jupyter.local  \
    -p 8888:8888 \
    --network net_pg \
    docker.io/jupyter/minimal-notebook \
    start.sh jupyter lab --NotebookApp.token=''
