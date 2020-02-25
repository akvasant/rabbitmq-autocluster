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
    LANGUAGE=en_US.UTF-8
ARG DEBIAN_FRONTEND=noninteractive
RUN \
  apt-get update -y && \
  apt-get install -y \
    coreutils curl xz-utils \
    erlang erlang-asn1 erlang-crypto erlang-eldap erlang-inets erlang-mnesia \
    erlang-os-mon erlang-public-key erlang-ssl erlang-syntax-tools erlang-xmerl && \
  curl -sL -o /tmp/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.gz https://www.rabbitmq.com/releases/rabbitmq-server/v${RABBITMQ_VERSION}/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.xz && \
  cd /usr/lib/ && \
  tar xf /tmp/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.gz && \
  rm /tmp/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.gz && \
  mv /usr/lib/rabbitmq_server-${RABBITMQ_VERSION} /usr/lib/rabbitmq && \
  curl -sL -o /usr/lib/rabbitmq/plugins/autocluster-${AUTOCLUSTER_VERSION}.ez https://github.com/rabbitmq/rabbitmq-autocluster/releases/download/${AUTOCLUSTER_VERSION}/autocluster-${AUTOCLUSTER_VERSION}.ez && \
curl -sL -o /usr/lib/rabbitmq/plugins/rabbitmq_aws-${AUTOCLUSTER_VERSION}.ez https://github.com/rabbitmq/rabbitmq-autocluster/releases/download/${AUTOCLUSTER_VERSION}/rabbitmq_aws-${AUTOCLUSTER_VERSION}.ez

COPY root/ /

# Fetch the external plugins and setup RabbitMQ
RUN \
  useradd -U -u 1001 -d $HOME -s /bin/bash rabbitmq && \
  cp /var/lib/rabbitmq/.erlang.cookie /root/ && \
  chown rabbitmq /var/lib/rabbitmq/.erlang.cookie && \
  chmod 0600 /var/lib/rabbitmq/.erlang.cookie /root/.erlang.cookie && \
  mkdir -p -m755 /var/log/rabbitmq && chown rabbitmq /var/log/rabbitmq && \
  chown -R rabbitmq /usr/lib/rabbitmq /var/lib/rabbitmq && sync && \
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
USER rabbitmq
EXPOSE 4369 5671 5672 15672 25672
ENTRYPOINT ["/launch.sh"]
CMD ["rabbitmq-server"]
