# Installation
sudo apt install -y podman dbus-x11

# Enable lingering: If you plan to run Podman as a user service or in the
# background, enabling lingering for your user might be a good idea:
sudo loginctl enable-linger `id -u`

# Create local directory for containers
mkdir ~/.config/containers

# Copy the template containers.conf file to the local directory
cp /usr/share/containers/containers.conf ~/.config/containers/

# Set "netavark" as network backend
sed 's:\(network_backend.*\):#\1\nnetwork_backend = "netavark":g' \
    -i ~/.config/containers/containers.conf

# Create the registers configuration file
cat << EOF > ~/.config/containers/registries.conf
[registries.search]
registries = ['docker.io', 'registry.fedoraproject.org', 'quay.io']
EOF

# Create a test podman network
podman network create net_test

# Create two test containers
podman container run -dit --name backend --network net_test alpine \
    sleep infinity

podman containerrun -dit --name frontend --network net_test alpine \
    sleep infinity

# Install need packages
podman exec frontend apk add iputils bind-tools

# Test ping
podman exec frontend ping -c 3 backend


# Delete everything that was created
podman container rm -f backend frontend
podman network rm net_test net_pg

