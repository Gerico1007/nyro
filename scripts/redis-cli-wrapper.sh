#!/bin/bash
#source "$(dirname "$0")/../.env"
source $HOME/.env

# Build Redis CLI command with TLS support
#redis-cli -u "$REDIS_URL" --tls "$@"
function wrapper_redis_cli_docker()
{
    docker run -it redis:alpine redis-cli --tls -u redis://default:$UPSTASH_REDIS_PASSWORD@$UPSTASH_REDIS_HOST:$UPSTASH_REDIS_PORT  "$@"
}

function _scan()
{

    wrapper_redis_cli_docker --scan --pattern "$@"
}
