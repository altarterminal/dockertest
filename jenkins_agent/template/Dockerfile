FROM ubuntu:22.04

ARG user=jenkins
ARG uid=<<uid>>
ARG gid=<<gid>>

RUN apt update && apt upgrade -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata
RUN apt install -y vim gawk wget git curl
RUN apt install -y sudo locales bash-completion openssh-server
RUN apt install -y openjdk-17-jre

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

RUN mkdir /home/${user}/.ssh
RUN chown ${user}:${user} /home/${user}/.ssh
COPY id_rsa.pub /home/${user}/.ssh/authorized_keys
RUN chown ${user}:${user} /home/${user}/.ssh/authorized_keys
RUN chmod 0600 /home/${user}/.ssh/authorized_keys

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
