FROM ubuntu:20.04

# The USER_ID argument will allow to the Docker Image user 
#  to inherit the same UID and GID from the user creating the Docker image
ARG USER_ID

# configure timezone
ENV TZ=Europe/Warsaw
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# These environment variables will also become available
#  when running a container. The IAR build tools 
#  are going to be on the search path
ENV IAR_PATH="/opt/iarsystems"
ENV IAR_BXARM_PATH="${IAR_PATH}/bxarm-8.50.9"
ENV IAR_LMS_SETTINGS_DIR="/.lms"
ENV IAR_BUILD_PATH="/build"
ENV PATH="${IAR_BXARM_PATH}/arm/bin:${IAR_BXARM_PATH}/common/bin:$PATH"

# install basic tools
RUN apt update; apt -y install curl make git g++ cmake fontconfig sudo libsqlite3-0

# Add an user to the image with the same UID and GID  
#  from the user creating the BXARM Docker image
#  the user is also added to the sudoers group on the image
RUN  useradd --create-home --uid ${USER_ID} ciuser && \
     echo "ciuser:ciuser" | chpasswd && \
     adduser ciuser sudo


# install C/C++test - be sure to customize, optimize, configure license etc. before building image
WORKDIR /opt/parasoft
COPY cpptest /opt/parasoft/cpptest

ENV PATH="/opt/parasoft/cpptest:$PATH"

# Copies the .deb package from the host to the image
COPY bxarm-8.50.9.deb /tmp

# Install the .deb package and then the installer from the image
RUN  dpkg --install /tmp/bxarm-8.50.9.deb && \
     rm /tmp/bxarm-8.50.9.deb

# Creates and sets the build directory
RUN  mkdir ${IAR_BUILD_PATH} && \
     chmod u+rwx -R ${IAR_BUILD_PATH} && \
     chmod g+rwx -R ${IAR_BUILD_PATH} && \
     chown ciuser:ciuser ${IAR_BUILD_PATH}
 
RUN /opt/iarsystems/bxarm/common/bin/lightlicensemanager init && \
    /opt/iarsystems/bxarm/common/bin/lightlicensemanager setup -s ananke.parasoft.com.pl
 
# install github runner
ENV GITHUB_RUNNER="/github-runner"

WORKDIR ${GITHUB_RUNNER}
COPY github-runner* ${GITHUB_RUNNER}/
RUN curl -O -L https://github.com/actions/runner/releases/download/v2.276.1/actions-runner-linux-x64-2.276.1.tar.gz; tar xzf ./actions-runner-linux-x64-2.276.1.tar.gz; chmod a+rwx -R ${GITHUB_RUNNER} 

# When the container is started, it will start from the ${IAR_BUILD_PATH} directory
USER ciuser
ENV LC_ALL=C
