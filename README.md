# Icinga 2 AlmaLinux 9 builder

Rebuilds Icinga 2 as RPMs for AlmaLinux 9. The image starts from an official EL8 source RPM, updates the spec for EL9, fetches the requested Icinga 2 tarball, and rebuilds with `mock`.

Set the version in the `Dockerfile` before building:

- `ICINGA_VERSION` — Icinga 2 tag to download and package (for example `2.16.5`)
- `ICINGA_SRPM_VERSION` — version of the bundled source RPM (currently `2.14.3`)

## Prerequisites

- Docker
- Docker Compose (for the recommended build)
- GitHub CLI (`gh`) if you create the release from the command line

## Build with Docker Compose (recommended)

This maps the built RPMs onto `./rpmbuild` on the host:

```bash
docker compose up --build
```

When the build finishes, packages are under `rpmbuild/` (typically `rpmbuild/x86_64/` and `rpmbuild/noarch/`).

## Build with Docker

```bash
docker build -t icinga2-alma-builder .
docker run --rm --privileged \
  -v "$(pwd)/rpmbuild:/root/rpmbuild/RPMS" \
  icinga2-alma-builder
```

`--privileged` is required for `mock`. The volume mount is the same as in `docker-compose.yml`, so RPMs land in `./rpmbuild` on the host.

Without the volume, packages stay in `/root/rpmbuild/RPMS/` inside the container. Copy them out with `docker cp` if you need them.

## Create a GitHub release

Publish the RPMs as a GitHub release so others can download them without rebuilding.

1. Confirm the packages you want to attach, for example:
   ```bash
   find rpmbuild -name '*.rpm' | sort
   ```
2. Commit any Dockerfile version bump and push to `main`.
3. Create a release whose tag matches `ICINGA_VERSION` (for example `v2.16.5`).

### GitHub CLI

From the repository root, after a successful build:

```bash
VERSION=2.16.5

gh release create "v${VERSION}" \
  --title "Icinga ${VERSION} for AlmaLinux 9" \
  --notes "RPM packages for Icinga ${VERSION} built for AlmaLinux 9." \
  $(find rpmbuild -name '*.rpm' | tr '\n' ' ')
```

If the tag already exists, add `--target main` only when creating a new tag; do not overwrite an existing release unless you intend to.

After the release is published, the RPMs are available on the GitHub release page for that tag.

### GitHub web UI

1. Open [Releases](https://github.com/DigistateBV/icinga2-alma-builder/releases).
2. Choose **Draft a new release**.
3. Create a new tag such as `v2.16.5` on `main`.
4. Set the title (for example `Icinga 2.16.5 for AlmaLinux 9`) and a short description of what was built.
5. Attach the RPM files from `rpmbuild/` (you can select the whole `x86_64` and `noarch` directories’ contents).
6. Publish the release.
