FROM ubuntu:22.04

ARG user=ansible
ARG uid=1000

RUN apt update && apt upgrade -y

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata

RUN apt install -y vim gawk wget git curl ansible
RUN apt install -y sudo locales bash-completion openssh-server

# ユーザに関する設定
RUN useradd -u ${uid} -m -d /home/${user} -G sudo ${user}
RUN echo "${user}:${user}" | chpasswd
RUN chsh -s /bin/bash ${user}
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN chown -R ${user} /home/${user}

# sshdの公開鍵認証の設定
RUN mkdir /var/run/sshd
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/'  /etc/ssh/sshd_config
RUN sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/'      /etc/ssh/sshd_config

CMD ["/usr/sbin/sshd", "-D"]
