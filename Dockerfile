FROM almalinux/9-base:latest

# Set the version of Icinga to build
ENV ICINGA_VERSION=2.14.5
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

# Update the spec file to use el9
RUN sed -i 's/el8/el9/g' /root/rpmbuild/SPECS/icinga2.spec && \
    sed -i 's/2.14.3/2.14.5/g' /root/rpmbuild/SPECS/icinga2.spec && \
    rpmbuild -bs /root/rpmbuild/SPECS/icinga2.spec

# Build the source RPM
RUN echo "mock -r almalinux-9-x86_64 --rebuild /root/rpmbuild/SRPMS/icinga2-${ICINGA_VERSION}-1.el9.src.rpm" > /root/build.sh

# Make the build script executable
RUN chmod +x /root/build.sh

# Run the build script
CMD ["bash", "/root/build.sh"]
