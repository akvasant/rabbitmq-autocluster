FROM ubuntu:18.04

# Version of RabbitMQ to install
ENV RABBITMQ_VERSION=3.6.14 \
    ERL_EPMD_PORT=4369 \
    AUTOCLUSTER_VERSION=0.10.0 \
    HOME=/var/lib/rabbitmq \
    PATH=/usr/lib/rabbitmq/sbin:$PATH \
    RABBITMQ_LOG_BASE=/var/log/rabbitmq \
    RABBITMQ_DIST_PORT=25672 \
    RABBITMQ_SERVER_ERL_ARGS="+K true +A128 +P 1048576 -kernel inet_default_connect_options [{nodelay,true}]" \
    RABBITMQ_MNESIA_DIR=/var/lib/rabbitmq/mnesia \
    RABBITMQ_PID_FILE=/var/lib/rabbitmq/rabbitmq.pid \
    RABBITMQ_PLUGINS_DIR=/usr/lib/rabbitmq/plugins \
    RABBITMQ_PLUGINS_EXPAND_DIR=/var/lib/rabbitmq/plugins \
    RABBITMQ_USER=rabbitmq \
    LANGUAGE=en_US.UTF-8
ARG DEBIAN_FRONTEND=noninteractive
RUN \
  apt-get update -y && \
  apt-get install -y \
    coreutils curl xz-utils \
    erlang erlang-asn1 erlang-crypto erlang-eldap erlang-inets erlang-mnesia \
    erlang-os-mon erlang-public-key erlang-ssl erlang-syntax-tools erlang-xmerl && \
    apt-get remove -y libapparmor1 xdg-user-dirs && \
    apt-get upgrade -y && \
  curl -sL -o /tmp/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.gz https://www.rabbitmq.com/releases/rabbitmq-server/v${RABBITMQ_VERSION}/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.xz && \
  cd /usr/lib/ && \
  tar xf /tmp/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.gz && \
  rm /tmp/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.gz && \
  mv /usr/lib/rabbitmq_server-${RABBITMQ_VERSION} /usr/lib/rabbitmq && \
  rm -rf /usr/lib/erlang/lib/inets-6.4.5/examples && \
  rm -rf /usr/lib/erlang/lib/ssl-8.2.3/examples && \
  curl -sL -o /usr/lib/rabbitmq/plugins/autocluster-${AUTOCLUSTER_VERSION}.ez https://github.com/rabbitmq/rabbitmq-autocluster/releases/download/${AUTOCLUSTER_VERSION}/autocluster-${AUTOCLUSTER_VERSION}.ez && \
curl -sL -o /usr/lib/rabbitmq/plugins/rabbitmq_aws-${AUTOCLUSTER_VERSION}.ez https://github.com/rabbitmq/rabbitmq-autocluster/releases/download/${AUTOCLUSTER_VERSION}/rabbitmq_aws-${AUTOCLUSTER_VERSION}.ez

COPY root/ /

# Fetch the external plugins and setup RabbitMQ
RUN \
  useradd -U -u 1100 -d $HOME -s /bin/bash ${RABBITMQ_USER} && \
  chown ${RABBITMQ_USER} $HOME/.erlang.cookie && \
  chmod 0600 $HOME/.erlang.cookie && \
  cp -p $HOME/.erlang.cookie /root/ && \
  mkdir -p -m755 ${RABBITMQ_LOG_BASE} && chown ${RABBITMQ_USER} ${RABBITMQ_LOG_BASE} && \
  chown -R ${RABBITMQ_USER} /usr/lib/rabbitmq $HOME && sync && \
  /usr/lib/rabbitmq/sbin/rabbitmq-plugins --offline enable \
    rabbitmq_management \
    rabbitmq_consistent_hash_exchange \
    rabbitmq_federation \
    rabbitmq_federation_management \
    rabbitmq_mqtt \
    rabbitmq_shovel \
    rabbitmq_shovel_management \
    rabbitmq_stomp \
    rabbitmq_web_stomp \
    autocluster

VOLUME $HOME
USER $RABBITMQ_USER
EXPOSE 4369 5671 5672 15672 25672
ENTRYPOINT ["/launch.sh"]
CMD ["rabbitmq-server"]
