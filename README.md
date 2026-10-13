<p align="center">
  <a href="https://digistate.nl/">
    <img src="pages/digistate.webp" alt="DigiState" width="221" height="50">
  </a>
</p>

# Icinga 2 packages for AlmaLinux

Unofficial Icinga 2 RPM rebuilds for **AlmaLinux 9** and **AlmaLinux 10**, published by [DigiState](https://digistate.nl/).

Packages are not GPG-signed. Use at your own risk.

**Install page:** https://digistatebv.github.io/icinga2-alma-builder/

## Install with dnf

On AlmaLinux 9 or 10:

```bash
sudo curl -fsSL -o /etc/yum.repos.d/icinga2-alma.repo \
  https://digistatebv.github.io/icinga2-alma-builder/icinga2-alma.repo
sudo dnf install icinga2
```

The repo file uses `$releasever`, so the host picks `el9` or `el10` automatically.

## Install with Ansible

```yaml
- name: Add DigiState Icinga 2 AlmaLinux repository
  ansible.builtin.yum_repository:
    name: icinga2-alma
    description: Icinga 2 for AlmaLinux $releasever (unofficial rebuild)
    baseurl: https://digistatebv.github.io/icinga2-alma-builder/el$releasever
    enabled: true
    gpgcheck: false

- name: Install Icinga 2
  ansible.builtin.package:
    name: icinga2
    state: present

- name: Enable and start Icinga 2
  ansible.builtin.service:
    name: icinga2
    enabled: true
    state: started
```

## Download RPMs directly

Individual packages are attached to [GitHub Releases](https://github.com/DigistateBV/icinga2-alma-builder/releases). Prefer the yum/dnf repo above for normal installs and updates.

---

## Rebuild the packages yourself

This repository also contains the Docker-based rebuild pipeline. Most users can skip this section.

The image starts from an official EL8 source RPM, updates the spec for the target EL version, fetches the requested Icinga 2 tarball, and rebuilds with `mock`.

**Prerequisites:** Docker, Docker Compose, and optionally GitHub CLI (`gh`) for releases.

### Build arguments

| Argument | Meaning | Default |
| --- | --- | --- |
| `ALMALINUX_VERSION` | Target major version (`9` or `10`) | `9` |
| `ICINGA_VERSION` | Icinga 2 tag to download and package | `2.16.5` |
| `ICINGA_SRPM_VERSION` | Bundled source RPM version | `2.14.3` |

`docker-compose.yml` defines two services:

| Service | Target | RPMs on the host |
| --- | --- | --- |
| `alma9` | AlmaLinux 9 | `rpmbuild-alma9/` |
| `alma10` | AlmaLinux 10 | `rpmbuild-alma10/` |

### Docker Compose (recommended)

```bash
docker compose up --build
```

One target only:

```bash
docker compose up --build alma9
docker compose up --build alma10
```

Finished packages land under `rpmbuild-alma9/` or `rpmbuild-alma10/` (typically `x86_64/` and `noarch/`).

### Plain Docker

AlmaLinux 9:

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

`--privileged` is required for `mock`. Without a volume, packages stay in `/root/rpmbuild/RPMS/` inside the container.

### Publish a release

Attach both EL9 and EL10 RPMs when both builds succeeded. Tag the release to match `ICINGA_VERSION` (for example `v2.16.5`).

```bash
VERSION=2.16.5

gh release create "v${VERSION}" \
  --title "Icinga ${VERSION} for AlmaLinux 9 and 10" \
  --notes "RPM packages for Icinga ${VERSION} built for AlmaLinux 9 (el9) and AlmaLinux 10 (el10)." \
  $(find rpmbuild-alma9 rpmbuild-alma10 -name '*.rpm' | tr '\n' ' ')
```

Or use the GitHub UI: [Releases](https://github.com/DigistateBV/icinga2-alma-builder/releases) → **Draft a new release** → attach the RPMs from `rpmbuild-alma9/` and `rpmbuild-alma10/`.

Publishing a release (or running **Deploy yum repository to GitHub Pages**) rebuilds the public yum/dnf repo on GitHub Pages. Pages must be set once to **Source: GitHub Actions**.
