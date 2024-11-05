#!/bin/sh

ACTION=${1}
shift 1

do_install() {
  local path=`uci get IStore.@IStore[0].cache_path 2>/dev/null`
  local uid=`uci get IStore.@IStore[0].uid 2>/dev/null`
  local image_name=`uci get IStore.@IStore[0].image_name 2>/dev/null`

  if [ -z "$path" ]; then
      echo "path is empty!"
      exit 1
  fi

  local netdev=`ip route list|awk ' /^default/ {print $5}'`
  if [ -z "$netdev" ]; then
      echo "defualt gateway is empty!"
      exit 1
  fi

  [ -z "$image_name" ] && image_name="jinshanyun/jinshan-x86_64:latest"
  echo "docker pull ${image_name}"
  docker pull ${image_name}
  docker rm -f IStore

  local cmd="docker run --restart=unless-stopped -d \
    --init \
    --privileged \
    --network=host \
    --dns=127.0.0.1 \
    --dns=223.5.5.5 \
    -v \"$path:/data/lsy_cloud\" \
    -e ksc_datadir=\"/data/lsy_cloud\" \
    -e ksc_net=\"$netdev\" \
    -e ksc_machine_code=\"lsyK18000_$uid\" "

  local tz="`uci get system.@system[0].zonename | sed 's/ /_/g'`"
  [ -z "$tz" ] || cmd="$cmd -e TZ=$tz"

  cmd="$cmd --name IStore \"$image_name\""

  echo "$cmd"
  eval "$cmd"

  if [ "$?" = "0" ]; then
    if [ "`uci -q get firewall.IStore.enabled`" = 0 ]; then
      uci -q batch <<-EOF >/dev/null
        set firewall.IStore.enabled="1"
        commit firewall
EOF
      /etc/init.d/firewall reload
    fi
  fi

  echo "Install OK!"

}

usage() {
  echo "usage: $0 sub-command"
  echo "where sub-command is one of:"
  echo "      install                Install the IStore"
  echo "      upgrade                Upgrade the IStore"
  echo "      rm/start/stop/restart  Remove/Start/Stop/Restart the IStore"
  echo "      status                 Onething Edge status"
  echo "      port                   Onething Edge port"
}

case ${ACTION} in
  "install")
    do_install
  ;;
  "upgrade")
    do_install
  ;;
  "rm")
    docker rm -f IStore
    if [ "`uci -q get firewall.IStore.enabled`" = 1 ]; then
      uci -q batch <<-EOF >/dev/null
        set firewall.IStore.enabled="0"
        commit firewall
EOF
      /etc/init.d/firewall reload
    fi
  ;;
  "start" | "stop" | "restart")
    docker ${ACTION} IStore
  ;;
  "status")
    docker ps --all -f 'name=^/IStore$' --format '{{.State}}'
  ;;
  "port")
    docker ps --all -f 'name=^/IStore$' --format '{{.Ports}}' | grep -om1 '0.0.0.0:[0-9]*' | sed 's/0.0.0.0://'
  ;;
  *)
    usage
    exit 1
  ;;
esac

