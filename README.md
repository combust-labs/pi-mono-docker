<!-- SPDX-License-Identifier: Apache-2.0 -->
# pi-mono Docker Build

This repository provides a minimal Docker image that runs the **pi-mono coding‑agent** (`pi‑mono`).

## What it contains
- **Dockerfile** – builds the image from `node:25‑trixie`, installs required tools, clones the `pi‑mono` source at the pinned version, builds it, and copies the `pi` CLI entry point.
- **`pi` script** – a tiny Node.js wrapper that sets up the process, configures an HTTP proxy via `undici`, imports the agent’s `main` module and forwards CLI arguments.
- **Makefile** – convenient target `make build-docker` that extracts the version from the Dockerfile and runs:
  ```
  docker build --no-cache -t localhost/pi-mono:<version> .
  ```

## How to build
```bash
make build-docker   # builds the image with the tag localhost/pi-mono:<version>
```
The `<version>` is taken from the `ARG PI_MONO_VERSION` line in the Dockerfile (default `v0.67.5`).

## Running the container
```bash
docker run -v $(pwd):/code -e HTTP_PROXY=... -e HTTPS_PROXY=... localhost/pi-mono:<version> <args>
```
Replace `<args>` with any command supported by the coding‑agent CLI.

## `ppi` execution modes
The helper script `ppi` provides two distinct ways to run the agent:

1. **Interactive CLI mode (default)** – When no `--port` flag is supplied, `ppi` runs the container with the default `pi` entry‑point. It forwards the selected model (via `--model`) and prompt (via `--prompt` or the default) directly to the CLI, printing the agent's response to the terminal. Use this for quick, one‑off queries.
   ```bash
   ppi                # runs the CLI inside the container
   ppi --model gpt-4  # specify a different model
   ```
   *Consequences*: the process runs synchronously, outputs to STDOUT/STDERR, and exits when the query is complete.

2. **HTTP‑RPC server mode** – Supplying `--port <n>` causes `ppi` to start the container with the `pi-rpc-http-server` entry‑point (`/opt/agent/pi-mono/node_modules/pi-rpc-http-server/bin/run.sh`). The agent listens on the given port (exposed as `3000` inside the container) and serves a JSON‑over‑HTTP API.
   ```bash
   ppi --port 3000   # start the RPC server
   ```
   *Consequences*: the container stays running, accepting HTTP requests; suitable for integration with other tools or remote clients. No direct CLI output is produced; interactions must be performed via HTTP calls.

Both modes mount the current project directory at `/code` and bind‑mount user configuration (`~/.gitconfig`, `~/.pi/agent/*`, etc.) into the container.

---

## Supported `ppi` Flags

The `ppi` script supports the following flags:

### String Flags
| Flag | Default | Description |
|------|---------|-------------|
| `--model <pattern>` | `gpt-oss-120b-MXFP4-Q8` | Model pattern or ID (supports `provider/id` and optional `:thinking`) |
| `--provider <name>` | (empty) | Provider name |
| `--system-prompt <text>` | (empty) | System prompt (default: coding assistant prompt) |
| `--append-system-prompt <text>` | (empty) | Append text to system prompt (allows multiple) |
| `--prompt <text>` | `Summarize current the project` | Initial prompt to send to the agent |
| `--thinking <level>` | (empty) | Thinking level: `off`, `minimal`, `low`, `medium`, `high`, `xhigh` |
| `--port <n>` | (CLI mode) | Start HTTP‑RPC server on port `n` |
| `--version <v>` | from Containerfile | Override pi‑mono container version |
| `--mode <text|json>` | `text` | Output mode (rpc value is disallowed) |
| `--session <path|id>` | (empty) | Use specific session |
| `--session-dir <dir>` | `/sessions` | Session storage directory (container path) |
| `--host-sessions-dir <dir>` | `$(pwd)/.pi/sessions` | Host directory to mount as /sessions volume |
| `--tools <tools>` | (empty) | Tool allowlist (allows multiple) |
| `--theme <path>` | (empty) | Load theme file/directory (allows multiple) |
| `--models <patterns>` | (empty) | Model cycling patterns (allows multiple) |
| `--list-models [search]` | (empty) | List available models (optional search term) |
| `--export <file>` | (empty) | Export session to HTML |
| `--extension <path>`, `-e` | (empty) | Load extension file (allows multiple) |
| `--skill <path>` | (empty) | Load skill file/directory (allows multiple) |
| `--prompt-template <path>` | (empty) | Load prompt template (allows multiple) |

### Boolean Flags
| Flag | Description |
|------|-------------|
| `--continue`, `-c` | Continue previous session |
| `--resume`, `-r` | Select and resume a session |
| `--no-session` | Don't save session (ephemeral mode) |
| `--verbose` | Force verbose startup |
| `--offline` | Disable startup network operations |
| `--print`, `-p` | Non‑interactive mode (process prompt and exit) |
| `--no-tools` | Disable all tools |
| `--no-extensions`, `-ne` | Disable extension discovery |
| `--no-skills`, `-ns` | Disable skills |
| `--no-prompt-templates`, `-np` | Disable prompt templates |
| `--no-themes` | Disable themes |
| `--no-context-files`, `-nc` | Disable AGENTS.md/CLAUDE.md context files |

### Examples
```bash
# Basic usage with default prompt
ppi

# Custom prompt
ppi --prompt "List all TypeScript files in src/"

# Different model with thinking level
ppi --model gpt-4o --thinking high "Analyze this code"

# Continue previous session
ppi --continue "What did we discuss last time?"

# With custom system prompt
ppi --system-prompt "You are a code reviewer" --prompt "Review PR #123"

# Start RPC server on port 3000
ppi --port 3000 --model gpt-4o
```

---

## Unsupported `pi` Flags

The following `pi` flags are not yet exposed through `ppi`:

- `--api-key` – API key (use environment variables instead)
- `--fork <path|id>` – Fork a session
- `--help`, `-h` – Show help
- `--version`, `-v` – Show version

---

### Hugging Face dataset

Session data is uploaded to the Hugging Face dataset `rgruchalski/combust-labs_pi-mono-docker`. You can view the datasets at https://huggingface.co/datasets/rgruchalski/combust-labs_pi-mono-docker

*Generated by **gpt-4***
