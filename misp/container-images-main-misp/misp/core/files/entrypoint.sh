#!/bin/bash

# export env variables again so they are not mandatory in docker-compose.yml in a backward compatible manner
# export NUM_WORKERS_DEFAULT=${NUM_WORKERS_DEFAULT:-${WORKERS:-5}}
# export NUM_WORKERS_PRIO=${NUM_WORKERS_PRIO:-${WORKERS:-5}}
# export NUM_WORKERS_EMAIL=${NUM_WORKERS_EMAIL:-${WORKERS:-5}}
# export NUM_WORKERS_UPDATE=${NUM_WORKERS_UPDATE:-${WORKERS:-1}}
# export NUM_WORKERS_CACHE=${NUM_WORKERS_CACHE:-${WORKERS:-5}}

check_env_var() {
  local var_name=$1
  local default_value=5

  if [ -z "${!var_name}" ]; then
    echo "$var_name is not set, defaulting to $default_value"
    export $var_name=$default_value
  fi
}

check_env_var "NUM_WORKERS_DEFAULT"
check_env_var "NUM_WORKERS_PRIO"
check_env_var "NUM_WORKERS_EMAIL"
check_env_var "NUM_WORKERS_UPDATE"
check_env_var "NUM_WORKERS_CACHE"

# Start supervisord using the main configuration file so we have a socket interface
/usr/bin/supervisord -m 777 -c /etc/supervisor/supervisord.conf
