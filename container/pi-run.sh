#!/bin/bash

# Base directory of this script (absolute path)
base=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

use_mode="interactive"

while (( "$#" )); do
    case "${1}" in
        --mode)
            use_mode="${2}"
            shift 2
            ;;
        *)
            echo "Error: Unsupported flag ${1}" >&2
            exit 1
            ;;
    esac
done

if [ "${use_mode}" == "interactive" ]; then
  chmod +x "${base}/pi-run-with-args.sh"
  "${base}/pi-run-with-args.sh"
elif [ "${use_mode}" == "rpc" ]; then
  /opt/agent/pi-mono/node_modules/pi-rpc-http-server/bin/run.sh
else
  echo "Error: Unsupported mode ${use_mode}" >&2
  exit 1
fi
