FROM ghcr.io/shadowsocks/ssserver-rust:latest

USER root

# qrencode нет в базовых репозиториях образа — без него сервер работает; ss:// всё равно в логах
RUN apk add --no-cache bash coreutils

COPY entrypoint_ss.sh /entrypoint_ss.sh
RUN chmod +x /entrypoint_ss.sh

ENTRYPOINT ["/entrypoint_ss.sh"]
