FROM alpine:latest

RUN apk add --no-cache git openssl bash openssh-client

RUN mkdir ~/.ssh && echo -e 'Host *\n\tStrictHostKeyChecking no' > ~/.ssh/config && chmod 400 ~/.ssh/config

RUN mkdir -p /workspace && chmod a+rwx /workspace

COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENV WORKSPACE=/workspace GIT_TERMINAL_PROMPT=1

WORKDIR /workspace

ENTRYPOINT [ "bash", "/entrypoint.sh" ]