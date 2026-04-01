#!/usr/bin/env bash
set -euo pipefail

# Mode utilitaire : lister les devices
if [ "${1:-}" = "list-devices" ]; then
    echo "=== ALSA devices (aplay -l) ==="
    aplay -l 2>/dev/null || echo "(no ALSA devices found)"
    echo ""
    echo "=== Sendspin audio devices ==="
    sendspin --list-audio-devices 2>/dev/null || true
    exit 0
fi

# Construction de la commande
CMD=(sendspin daemon)
CMD+=(--name "${SENDSPIN_NAME}")

[ -n "${SENDSPIN_CLIENT_ID}" ]        && CMD+=(--id "${SENDSPIN_CLIENT_ID}")
[ -n "${SENDSPIN_AUDIO_DEVICE}" ]     && CMD+=(--audio-device "${SENDSPIN_AUDIO_DEVICE}")
[ -n "${SENDSPIN_SERVER_URL}" ]       && CMD+=(--url "${SENDSPIN_SERVER_URL}")
[ -n "${SENDSPIN_AUDIO_FORMAT}" ]     && CMD+=(--audio-format "${SENDSPIN_AUDIO_FORMAT}")
[ -n "${SENDSPIN_STATIC_DELAY_MS}" ]  && CMD+=(--static-delay-ms "${SENDSPIN_STATIC_DELAY_MS}")
[ -n "${SENDSPIN_HOOK_START}" ]       && CMD+=(--hook-start "${SENDSPIN_HOOK_START}")
[ -n "${SENDSPIN_HOOK_STOP}" ]        && CMD+=(--hook-stop "${SENDSPIN_HOOK_STOP}")
[ -n "${SENDSPIN_HOOK_SET_VOLUME}" ]  && CMD+=(--hook-set-volume "${SENDSPIN_HOOK_SET_VOLUME}")
[ -n "${SENDSPIN_PORT}" ]             && CMD+=(--port "${SENDSPIN_PORT}")

CMD+=(--hardware-volume "${SENDSPIN_HARDWARE_VOLUME}")
CMD+=(--log-level "${SENDSPIN_LOG_LEVEL}")

echo "───────────────────────────────────────"
echo "  Sendspin Receiver"
echo "  Name:   ${SENDSPIN_NAME}"
echo "  Device: ${SENDSPIN_AUDIO_DEVICE:-auto}"
echo "  Port:   ${SENDSPIN_PORT}"
echo "───────────────────────────────────────"
echo "CMD: ${CMD[*]}"
echo ""

exec "${CMD[@]}"
