ARG ALMALINUX_VERSION=9
ARG ICINGA_VERSION=2.16.5

FROM almalinux/${ALMALINUX_VERSION}-base:latest

# ARGs before FROM are only available in FROM; re-declare them for later steps.
ARG ALMALINUX_VERSION
ARG ICINGA_VERSION

# Set the version of the source RPM
ENV ICINGA_SRPM_VERSION=2.14.3

# Install dependencies
RUN dnf install -y gcc gcc-c++ make cmake openssl-devel boost-devel bison flex epel-release && \
    dnf install -y mock rpm-build

# Copy the source RPM to the container
COPY icinga2-${ICINGA_SRPM_VERSION}-1.el8.src.rpm /tmp/icinga2-${ICINGA_SRPM_VERSION}-1.el8.src.rpm

# Install the source RPM
RUN rpm -ihv /tmp/icinga2-${ICINGA_SRPM_VERSION}-1.el8.src.rpm && rm -f /tmp/icinga2-${ICINGA_SRPM_VERSION}-1.el8.src.rpm

# Download the source tarball
ADD https://github.com/Icinga/icinga2/archive/refs/tags/v${ICINGA_VERSION}.tar.gz /root/rpmbuild/SOURCES/icinga2-${ICINGA_VERSION}.tgz

# Update the spec file for the target AlmaLinux version
RUN sed -i "s/el8/el${ALMALINUX_VERSION}/g" /root/rpmbuild/SPECS/icinga2.spec && \
    sed -i "s/2.14.3/${ICINGA_VERSION}/g" /root/rpmbuild/SPECS/icinga2.spec && \
    sed -i "s/-DICINGA2_GROUP=icinga /-DICINGA2_GROUP=icinga -DICINGA2_WITH_OPENTELEMETRY=OFF /g" /root/rpmbuild/SPECS/icinga2.spec && \
    sed -i "s/BuildRequires: systemd-devel/BuildRequires: systemd-devel\nBuildRequires: protobuf-devel\nBuildRequires: protobuf-lite-devel/g" /root/rpmbuild/SPECS/icinga2.spec && \
    sed -i 's/COPYING/LICENSE.md/g' /root/rpmbuild/SPECS/icinga2.spec && \
    sed -i 's/License: GPLv2+/License: GPLv3+/' /root/rpmbuild/SPECS/icinga2.spec && \
    rpmbuild -bs /root/rpmbuild/SPECS/icinga2.spec

# Build the source RPM
RUN echo "mock -r almalinux-${ALMALINUX_VERSION}-x86_64 --rebuild /root/rpmbuild/SRPMS/icinga2-${ICINGA_VERSION}-1.el${ALMALINUX_VERSION}.src.rpm --define \"_smp_mflags -j$(nproc)\"" > /root/build.sh

# Make the build script executable
RUN chmod +x /root/build.sh

# Run the build script
CMD ["bash", "/root/build.sh"]
