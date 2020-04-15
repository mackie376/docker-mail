FROM alpine:3.11
LABEL maintainer "Takashi Makimoto <mackie@beehive-dev.com>"

ARG USER_NAME=mackie
ARG USER_ID=1000
ARG WORKSPACE=Downloads

RUN apk --update --no-cache --no-progress add \
      isync \
      jq \
      msmtp \
      notmuch \
      sudo \
      vim \
      w3m && \
    apk add --no-progress --virtual .to_remove gettext tzdata && \
    apk add --no-cache --no-progress --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing neomutt && \
    cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    cp /usr/bin/envsubst /usr/local/bin/envsubst && \
    adduser -D -u "$USER_ID" "$USER_NAME" "$USER_NAME" && \
    echo "${USER_NAME}:${USER_NAME}" | chpasswd && \
    addgroup -g 150 sudo && \
    addgroup "$USER_NAME" sudo && \
    sed -i 's/^# \(%sudo.*\)/\1/g' /etc/sudoers && \
    apk del .to_remove && \
    rm -rf /var/cache/apk/*

COPY bin/run.sh /usr/local/bin/run.sh
COPY config "/home/${USER_NAME}/.config/neomutt"
COPY template /tmp

RUN chown -R "${USER_NAME}:${USER_NAME}" "/home/${USER_NAME}/.config"

USER "$USER_ID"
WORKDIR "/home/${USER_NAME}"

RUN mkdir -p "/home/${USER_NAME}/.maildir" && \
    mkdir -p "/home/${USER_NAME}/${WORKSPACE}"

WORKDIR "/home/${USER_NAME}/${WORKSPACE}"
ENTRYPOINT ["run.sh"]
