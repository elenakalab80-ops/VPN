FROM ghcr.io/shadowsocks/ssserver-rust:latest

USER root

RUN apk add --no-cache bash coreutils qrencode

COPY entrypoint_ss.sh /entrypoint_ss.sh
RUN chmod +x /entrypoint_ss.sh

ENTRYPOINT ["/entrypoint_ss.sh"]
