FROM ubuntu:22.04

ARG user=ansible
ARG uid=501

RUN apt update && apt upgrade -y

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata

RUN apt install -y vim gawk wget git curl ansible

RUN apt install -y sudo
RUN apt install -y locales

RUN useradd -u ${uid} -m -d /home/${user} -G sudo ${user}
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN chown -R ${user} /home/${user}

CMD ["/bin/bash"]
