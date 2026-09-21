# Icinga 2 AlmaLinux builder

Rebuilds Icinga 2 as RPMs for AlmaLinux 9 and AlmaLinux 10 from a single Dockerfile. The image starts from an official EL8 source RPM, updates the spec for the target EL version, fetches the requested Icinga 2 tarball, and rebuilds with `mock`.

Build arguments:

- `ALMALINUX_VERSION` — target major version (`9` or `10`; default `9`)
- `ICINGA_VERSION` — Icinga 2 tag to download and package (default `2.16.5`)
- `ICINGA_SRPM_VERSION` — version of the bundled source RPM (currently `2.14.3`)

`docker-compose.yml` defines two services that pass `ALMALINUX_VERSION`:

| Service | Target        | RPMs on the host     |
| ------- | ------------- | -------------------- |
| `alma9` | AlmaLinux 9   | `rpmbuild-alma9/`    |
| `alma10`| AlmaLinux 10  | `rpmbuild-alma10/`   |

## Prerequisites

- Docker
- Docker Compose (for the recommended build)
- GitHub CLI (`gh`) if you create the release from the command line

## Build with Docker Compose (recommended)

Build and run both targets:

```bash
docker compose up --build
```

Build one target only:

```bash
docker compose up --build alma9
docker compose up --build alma10
```

When a build finishes, packages are under the matching host directory
(typically `x86_64/` and `noarch/` inside `rpmbuild-alma9/` or
`rpmbuild-alma10/`).

## Build with Docker

AlmaLinux 9 (the default):

```bash
docker build -t icinga2-alma-builder:9 --build-arg ALMALINUX_VERSION=9 .
docker run --rm --privileged \
  -v "$(pwd)/rpmbuild-alma9:/root/rpmbuild/RPMS" \
  icinga2-alma-builder:9
```

AlmaLinux 10:

```bash
docker build -t icinga2-alma-builder:10 --build-arg ALMALINUX_VERSION=10 .
docker run --rm --privileged \
  -v "$(pwd)/rpmbuild-alma10:/root/rpmbuild/RPMS" \
  icinga2-alma-builder:10
```

`--privileged` is required for `mock`. The volume mounts match
`docker-compose.yml`.

Without a volume, packages stay in `/root/rpmbuild/RPMS/` inside the
container. Copy them out with `docker cp` if you need them.

## Create a GitHub release

Publish the RPMs as a GitHub release so others can download them without
rebuilding. Attach both the EL9 and EL10 packages when both builds succeeded.

1. Confirm the packages you want to attach, for example:

   ```bash
   find rpmbuild-alma9 rpmbuild-alma10 -name '*.rpm' | sort
   ```

2. Commit any Dockerfile version bump and push to `main`.
3. Create a release whose tag matches `ICINGA_VERSION` (for example `v2.16.5`).

### GitHub CLI

From the repository root, after successful builds:

```bash
VERSION=2.16.5

gh release create "v${VERSION}" \
  --title "Icinga ${VERSION} for AlmaLinux 9 and 10" \
  --notes "RPM packages for Icinga ${VERSION} built for AlmaLinux 9 (el9) and AlmaLinux 10 (el10)." \
  $(find rpmbuild-alma9 rpmbuild-alma10 -name '*.rpm' | tr '\n' ' ')
```

If the tag already exists, add `--target main` only when creating a new tag;
do not overwrite an existing release unless you intend to.

After the release is published, the RPMs are available on the GitHub release
page for that tag.

### GitHub web UI

1. Open [Releases](https://github.com/DigistateBV/icinga2-alma-builder/releases).
2. Choose **Draft a new release**.
3. Create a new tag such as `v2.16.5` on `main`.
4. Set the title (for example `Icinga 2.16.5 for AlmaLinux 9 and 10`) and a short description of what was built.
5. Attach the RPM files from `rpmbuild-alma9/` and `rpmbuild-alma10/` (you can select the `x86_64` and `noarch` contents of each).
6. Publish the release.
