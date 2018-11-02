FROM phusion/baseimage:0.10.1

CMD ["/sbin/my_init"]

RUN rm -f /etc/service/sshd/down

RUN sed -i "s/PasswordAuthentication\ *no/PasswordAuthentication yes/g" /etc/ssh/sshd_config

RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

RUN service ssh reload

# TODO: some scenarios expose different ports, this maybe should go into the configuration
EXPOSE 22

RUN apt-get update
RUN apt-get install -y sudo
RUN apt-get install -y net-tools

RUN useradd \
      --home-dir /home/james \
      --create-home \
      --shell /bin/bash \
      --groups sudo \
      --password $(echo s00p3rs3cr37 | openssl passwd -1 -stdin) \
      james

RUN echo "Hi there!" > /home/james/message
RUN chown james:james /home/james/message

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

