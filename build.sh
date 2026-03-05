#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Windoos build wrapper (JSON templates)

Usage:
  ./scripts/build.sh -p <vmware|virtualbox> -t <windows_10|windows_11> [-f <template.json>] [-r <restart_timeout>] [-H <true|false>]

Examples:
  ./scripts/build.sh -p vmware    -t windows_10
  ./scripts/build.sh -p virtualbox -t windows_10
  ./scripts/build.sh -p vmware -f windows_10.json -H true

Notes:
- This wrapper runs Packer from ./packer so JSON-relative paths like ./scripts/... work.
- It uses -only to select the right builder for the chosen provider.
EOF
}

PROVIDER=""
TARGET=""
TEMPLATE_JSON=""
HEADLESS=""
RESTART_TIMEOUT=""

while getopts ":p:t:f:H:r:h" opt; do
  case "${opt}" in
  p) PROVIDER="${OPTARG}" ;;
  t) TARGET="${OPTARG}" ;;
  f) TEMPLATE_JSON="${OPTARG}" ;;
  H) HEADLESS="${OPTARG}" ;;
  r) RESTART_TIMEOUT="${OPTARG}" ;;
  h)
    usage
    exit 0
    ;;
  \?)
    echo "Unknown option: -${OPTARG}" >&2
    usage
    exit 2
    ;;
  :)
    echo "Missing argument for -${OPTARG}" >&2
    usage
    exit 2
    ;;
  esac
done

if [[ -z "${PROVIDER}" ]]; then
  echo "Error: -p <vmware|virtualbox> is required" >&2
  usage
  exit 2
fi

if [[ "${PROVIDER}" != "vmware" && "${PROVIDER}" != "virtualbox" ]]; then
  echo "Error: provider must be vmware or virtualbox" >&2
  exit 2
fi

# template selection:
# - if -f provided, use it
# - else require -t and map it to packer/<target>.json (e.g. windows_10.json)
if [[ -z "${TEMPLATE_JSON}" ]]; then
  if [[ -z "${TARGET}" ]]; then
    echo "Error: provide either -f <template.json> or -t <windows_10|windows_11>" >&2
    usage
    exit 2
  fi
  TEMPLATE_JSON="${TARGET}.json"
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/." && pwd)"
PACKER_DIR="${ROOT_DIR}/packer"
TEMPLATE_PATH="${PACKER_DIR}/${TEMPLATE_JSON}"

if [[ ! -f "${TEMPLATE_PATH}" ]]; then
  echo "Error: template not found: ${TEMPLATE_PATH}" >&2
  exit 2
fi

# In JSON templates, -only uses builder "type" and optional "name".
# Your builders have only "type", so these are:
# - vmware-iso
# - virtualbox-iso
if [[ "${PROVIDER}" == "vmware" ]]; then
  ONLY="vmware-iso"
else
  ONLY="virtualbox-iso"
fi

echo "[Windoos] Root: ${ROOT_DIR}"
echo "[Windoos] Packer dir: ${PACKER_DIR}"
echo "[Windoos] Template: ${TEMPLATE_JSON}"
echo "[Windoos] Provider: ${PROVIDER} (only=${ONLY})"

cd "${PACKER_DIR}"

# Build args
ARGS=(build "-only=${ONLY}")

# Optional overrides (only if you want to override variables defined in the JSON "variables" block)
if [[ -n "${HEADLESS}" ]]; then
  ARGS+=("-var" "headless=${HEADLESS}")
fi

if [[ -n "${RESTART_TIMEOUT}" ]]; then
  ARGS+=("-var" "restart_timeout=${RESTART_TIMEOUT}")
fi

# Run
packer "${ARGS[@]}" "${TEMPLATE_JSON}"
