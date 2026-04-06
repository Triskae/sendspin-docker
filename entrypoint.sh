#!/usr/bin/env bash
set -euo pipefail

# Utility mode: list available audio devices
if [ "${1:-}" = "list-devices" ]; then
    echo "=== ALSA devices (aplay -l) ==="
    aplay -l 2>/dev/null || echo "(no ALSA devices found)"
    echo ""
    echo "=== Sendspin audio devices ==="
    sendspin --list-audio-devices 2>/dev/null || true
    exit 0
fi

# Derive a stable client ID from SENDSPIN_NAME if not explicitly set
if [ -z "${SENDSPIN_CLIENT_ID}" ]; then
    SENDSPIN_CLIENT_ID=$(echo "${SENDSPIN_NAME}" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/-$//')
fi

# Auto-detect audio device if not specified
if [ -z "${SENDSPIN_AUDIO_DEVICE}" ]; then
    DETECTED=$(sendspin --list-audio-devices 2>/dev/null \
        | grep -E '^\s+\[[0-9]+\]' \
        | grep -iv 'default\|sysdefault\|dmix\|null' \
        | head -1 \
        | grep -oE '\[[0-9]+\]' \
        | tr -d '[]')
    if [ -n "${DETECTED}" ]; then
        SENDSPIN_AUDIO_DEVICE="${DETECTED}"
        echo "  Auto-detected audio device: ${DETECTED}"
    else
        echo "  No device detected, using sendspin default"
    fi
fi

# Build the command
CMD=(sendspin daemon)
CMD+=(--name "${SENDSPIN_NAME}")

DAEMON_HELP="$(sendspin daemon -h 2>&1 || true)"

[ -n "${SENDSPIN_CLIENT_ID}" ]        && CMD+=(--id "${SENDSPIN_CLIENT_ID}")
[ -n "${SENDSPIN_AUDIO_DEVICE}" ]     && CMD+=(--audio-device "${SENDSPIN_AUDIO_DEVICE}")
[ -n "${SENDSPIN_SERVER_URL}" ]       && CMD+=(--url "${SENDSPIN_SERVER_URL}")
[ -n "${SENDSPIN_AUDIO_FORMAT}" ]     && CMD+=(--audio-format "${SENDSPIN_AUDIO_FORMAT}")
[ -n "${SENDSPIN_STATIC_DELAY_MS}" ]  && CMD+=(--static-delay-ms "${SENDSPIN_STATIC_DELAY_MS}")
[ -n "${SENDSPIN_HOOK_START}" ]       && CMD+=(--hook-start "${SENDSPIN_HOOK_START}")
[ -n "${SENDSPIN_HOOK_STOP}" ]        && CMD+=(--hook-stop "${SENDSPIN_HOOK_STOP}")
[ -n "${SENDSPIN_HOOK_SET_VOLUME}" ]  && CMD+=(--hook-set-volume "${SENDSPIN_HOOK_SET_VOLUME}")
[ -n "${SENDSPIN_PORT}" ]             && CMD+=(--port "${SENDSPIN_PORT}")

if [ -n "${SENDSPIN_MANUFACTURER}" ]; then
    if echo "${DAEMON_HELP}" | grep -q -- '--manufacturer'; then
        CMD+=(--manufacturer "${SENDSPIN_MANUFACTURER}")
    else
        echo "  Warning: SENDSPIN_MANUFACTURER ignored (installed sendspin CLI does not support --manufacturer)"
    fi
fi

if [ -n "${SENDSPIN_PRODUCT_NAME}" ]; then
    if echo "${DAEMON_HELP}" | grep -q -- '--product-name'; then
        CMD+=(--product-name "${SENDSPIN_PRODUCT_NAME}")
    else
        echo "  Warning: SENDSPIN_PRODUCT_NAME ignored (installed sendspin CLI does not support --product-name)"
    fi
fi

CMD+=(--hardware-volume "${SENDSPIN_HARDWARE_VOLUME}")
CMD+=(--log-level "${SENDSPIN_LOG_LEVEL}")

SENDSPIN_CLI_VERSION="$(sendspin --version 2>/dev/null | head -n1 || echo unknown)"

echo "───────────────────────────────────────"
echo "  Sendspin Receiver"
echo "  Container Version: ${SENDSPIN_DOCKER_VERSION}"
echo "  Sendspin CLI:      ${SENDSPIN_CLI_VERSION}"
echo "  Name:   ${SENDSPIN_NAME}"
echo "  ID:     ${SENDSPIN_CLIENT_ID}"
echo "  Device: ${SENDSPIN_AUDIO_DEVICE:-auto}"
echo "  Port:   ${SENDSPIN_PORT}"
echo "───────────────────────────────────────"
echo "CMD: ${CMD[*]}"
echo ""

exec "${CMD[@]}"
