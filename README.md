# Building Icinga2 for Alma9
# Build using Docker
To build the rpm, run the following commands:
```
docker run --privileged .
```
The rpm files are in `/root/rpmbuild/RPMS/` inside the container.

## Build using docker compose
Use the docker compose file to build the rpm:
```
docker compose up --build
```
# The rpm will be in the rpmbuild/RPMS/ directory
