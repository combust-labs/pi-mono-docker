#!/bin/bash
base=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# File is delivered by the ppi program.
chmod +x "${base}/pi-run-with-args.sh"
"${base}/pi-run-with-args.sh"
