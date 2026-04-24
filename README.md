<!-- SPDX-License-Identifier: Apache-2.0 -->
# pi-mono Docker Build

This repository provides a comprehensive Docker image that runs the **pi-mono coding-agent** (`pi-mono`).

## What it contains
- **`container/Containerfile`** - builds the image from `node:25-trixie`, installs required tools, clones the `pi-mono` source at the pinned version, builds it, and copies the `pi` CLI entry point.
- **`container/pi-run.sh`** - container entrypoint that delegates to a generated shell script containing all CLI arguments
- **`container/pi`** - helper script copied into the image as the `pi` CLI entry point
- **`.pnpm-rc`, `.npmrc`, `.bunfig.toml`, `.config-uv-uv.toml`** - configuration files for pnpm, npm, bun, and uv package managers used during image build
- **`Makefile`** – convenient target `make build-docker` that extracts the version from `container/Containerfile` and runs:
  ```
  docker build --no-cache -t localhost/pi-mono:<version> .
  ```
- **`ppi`** – helper script on the host that runs the container in CLI mode or HTTP-RPC server mode

## How to build
```bash
make build-docker   # builds the image with the tag localhost/pi-mono:<version>
```
The `<version>` is taken from the `ARG PI_MONO_VERSION` line in `container/Containerfile` (default `v0.67.6`).

The following build args are supported:

| Build Arg | Default | Description |
|-----------|---------|-------------|
| `PI_MONO_VERSION` | `v0.67.6` | Version of pi-mono to clone and build |
| `PI_RPC_HTTP_SERVER_VERSION` | (empty) | Version of pi-rpc-http-server to install (uses pi-mono version if empty) |
| `NPM_VERSION` | (empty) | Specific npm version to install (optional) |
| `NODE_VERSION` | `25` | Node.js version to use (reflected in `node:<VERSION>-trixie` base) |

## Running the container
```bash
docker run \
  -v $(pwd):/code \
  -e HTTP_PROXY=... \
  -e HTTPS_PROXY=... \
  localhost/pi-mono:<version> \
  <args>
```
Replace `<args>` with any command supported by the coding-agent CLI.

## `ppi` execution modes
The helper script `ppi` provides two distinct ways to run the agent:

1. **Interactive CLI mode (default)** - When `--mode rpc` is not specified, `ppi` generates a temporary shell script containing all CLI arguments and mounts it into the container. The container's entrypoint (`pi-run.sh`) executes this script, which calls the `pi` CLI directly. Use this for quick, one-off queries.
   ```bash
   ppi                # runs the CLI inside the container
   ppi --model gpt-4  # specify a different model
   ```
   *Consequences*: the process runs synchronously, outputs to STDOUT/STDERR, and exits when the query is complete.

2. **HTTP-RPC server mode** - Supplying `--mode rpc` causes `ppi` to start the container with the `pi-rpc-http-server` entry-point (`/opt/agent/pi-mono/node_modules/pi-rpc-http-server/bin/run.sh`). The agent listens on the configured port (default `3000` inside the container) and serves a JSON-over-HTTP API.
   ```bash
   ppi --mode rpc   # start the RPC server (default port 3000)
   ppi --mode rpc --ppi-container-port 8080  # custom container port
   ppi --mode rpc --ppi-host-port 9000      # custom host port
   ```
   *Consequences*: the container stays running, accepting HTTP requests; suitable for integration with other tools or remote clients. No direct CLI output is produced; interactions must be performed via HTTP calls.

Both modes mount the current project directory at `/code` and bind-mount user configuration (`~/.gitconfig`, `~/.pi/agent/*`, etc.) into the container.

---

## Supported `ppi` Flags

The `ppi` script supports the following flags, segregated into flags inherited from `pi` and ppi-specific flags.

### `pi`-supported String Flags
| Flag | Default | Description |
|------|---------|-------------|
| `--append-system-prompt <text>` | nickname injection | Append text to system prompt (default: sets agent nickname to model name; allows multiple) |
| `--export <file>` | (empty) | Export session to HTML |
| `--extension <path>`, `-e` | (empty) | Load extension file (allows multiple) |
| `--list-models [search]` | enabled | List available models (optional search term; enabled when flag is present) |
| `--mode <text\|json\|rpc>` | `text` | Output mode (`rpc` triggers HTTP-RPC server mode) |
| `--model <pattern>` | (required) | Model pattern or ID (supports `provider/id` and optional `:thinking`) |
| `--prompt <text>` | `Summarize current the project` | Initial prompt to send to the agent |
| `--prompt-template <path>` | (empty) | Load prompt template (allows multiple) |
| `--provider <name>` | (empty) | Provider name |
| `--session <path\|id>` | (empty) | Use specific session |
| `--session-dir <dir>` | `/sessions` | Session storage directory (container path) |
| `--skill <path>` | (empty) | Load skill file/directory (allows multiple) |
| `--system-prompt <text>` | (empty) | System prompt (default: coding assistant prompt) |
| `--theme <path>` | (empty) | Load theme file/directory (allows multiple) |
| `--thinking <level>` | (empty) | Thinking level: `off`, `minimal`, `low`, `medium`, `high`, `xhigh` |
| `--tools <tools>` | (empty) | Tool allowlist (allows multiple) |

### `pi`-supported Boolean Flags
| Flag | Description |
|------|-------------|
| `--continue`, `-c` | Continue previous session |
| `--no-context-files`, `-nc` | Disable AGENTS.md/CLAUDE.md context files |
| `--no-extensions`, `-ne` | Disable extension discovery |
| `--no-prompt-templates`, `-np` | Disable prompt templates |
| `--no-session` | Don't save session (ephemeral mode) |
| `--no-skills`, `-ns` | Disable skills |
| `--no-themes` | Disable themes |
| `--no-tools` | Disable all tools |
| `--offline` | Disable startup network operations |
| `--print`, `-p` | Non-interactive mode (process prompt and exit) |
| `--resume`, `-r` | Select and resume a session |
| `--verbose` | Force verbose startup |

### ppi-specific String Flags
| Flag | Default | Description |
|------|---------|-------------|
| `--host-sessions-dir <dir>` | `$(pwd)/.pi/sessions` | Host directory to mount as /sessions volume |
| `--ppi-container-port <n>` | `3000` | Internal container port (used in `-e PORT` env var) |
| `--ppi-host-add-path <path>` | (empty) | Add custom volume mount (format: `host-path:container-path:rw` or `host-path:container-path:ro`; allows multiple) |
| `--ppi-host-port <n>` | (container port) | Host port exposed to localhost; defaults to container port if not set |
| `--version <v>` | from Containerfile | Override pi-mono container version |

### ppi-specific Boolean Flags
| Flag | Description |
|------|-------------|
| `--ppi-host-attach-agents` | Attach agents directory to container |
| `--ppi-host-attach-models-json` | Attach models.json file to container |
| `--ppi-host-attach-prompts` | Attach prompts directory to container |
| `--ppi-no-ppi-prompts` | Skip prepending the default nickname prompt |

### Default Nickname Injection

By default, `ppi` automatically prepends a system prompt that sets the agent's nickname to the selected model name:
```
Your nickname is unconditionally `<model>`, do not reinterpret. Use this value whenever you need to introduce yourself.
```
This ensures the agent consistently uses the model name as its identity. User-provided `--append-system-prompt` values are appended after this default.

Use `--ppi-no-ppi-prompts` to disable this behavior and start with a clean system prompt.

### Examples
```bash
# Basic usage with default prompt
# Note: This call requires --model to be specified explicitly. It also
# needs the models.json path via --ppi-host-attach-models-json or a
# custom mount via --ppi-host-add-path
ppi --model gpt-4o

# Custom prompt
ppi --prompt "List all TypeScript files in src/"

# Different model with thinking level
ppi --model gpt-4o --thinking high "Analyze this code"

# Continue previous session
ppi --continue "What did we discuss last time?"

# With custom system prompt
ppi --system-prompt "You are a code reviewer" --prompt "Review PR #123"

# Start RPC server on default port 3000
ppi --mode rpc

# Start RPC server with custom ports
ppi --mode rpc --ppi-container-port 8080
ppi --mode rpc --ppi-host-port 9000 --ppi-container-port 8080

# With prompts, agents and models.json directories attached
ppi --ppi-host-attach-prompts --ppi-host-attach-agents --ppi-host-attach-models-json "Analyze this code"

# With custom volume mounts
ppi --ppi-host-add-path /path/to/config:/root/.config:ro --ppi-host-add-path /path/to/data:/data:rw "Process data"
```

By default, `ppi` doesn't mount any `pi` configuration from the host. If your `ppi` invocations involve a wider number of flags, you may want to create a `bash` function to apply them automatically. For example:

```bash
function ppi {
  "${HOME}/.local/bin/ppi" \
    --ppi-host-attach-models-json \
    --ppi-host-attach-agents \
    --ppi-host-attach-prompts \
    --ppi-host-add-path "${HOME}/.gitconfig:/root/.gitconfig:ro" \
    --ppi-host-add-path "${HOME}/.gitconfig-github-private.inc:/root/.gitconfig-github-private.inc:ro" \
    --ppi-host-add-path "${HOME}/.pi/agent/extensions/read-website:/root/.pi/agent/extensions/read-website:ro" \
    --ppi-host-add-path "${HOME}/.pi/agent/extensions/subagent:/root/.pi/agent/extensions/subagent:ro" \
    "$@"
}
```

---

## Unsupported `pi` Flags

The following `pi` flags are not yet exposed through `ppi`:

- `--api-key` - API key (use environment variables instead)
- `--fork <path|id>` - Fork a session
- `--help`, `-h` - Show help
- `--version`, `-v` - Show version

---

### Hugging Face dataset

Session data is uploaded to the Hugging Face dataset `rgruchalski/combust-labs_pi-mono-docker`. You can view the datasets at https://huggingface.co/datasets/rgruchalski/combust-labs_pi-mono-docker

*Generated by **gpt-4***
