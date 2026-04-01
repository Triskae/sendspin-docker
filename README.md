# sendspin-receiver

Docker container that turns a USB speaker into a permanent [Sendspin](https://github.com/Sendspin-Protocol/sendspin) receiver.
Runs `sendspin daemon`, talks directly to ALSA (no PulseAudio/PipeWire), and advertises itself via mDNS on your local network.

---

## Quick start

```bash
curl -O https://raw.githubusercontent.com/<user>/sendspin-receiver/main/compose.yaml
docker compose up -d
```

That's it. With a single USB audio device plugged in, the receiver auto-detects it and starts advertising on the network.

---

## Configuration

All settings are optional — the receiver works out of the box with sensible defaults.
Override any variable directly in `compose.yaml` or via a `.env` file alongside it.

| Variable | Default | Description |
|---|---|---|
| `SENDSPIN_NAME` | `Sendspin Speaker` | Name shown in the Sendspin app |
| `SENDSPIN_AUDIO_DEVICE` | *(auto)* | Device index or ALSA name — auto-detected if empty |
| `SENDSPIN_PORT` | `8927` | Listening port |
| `SENDSPIN_HARDWARE_VOLUME` | `true` | Hardware volume control |
| `SENDSPIN_SERVER_URL` | *(mDNS)* | WebSocket server URL — leave empty for auto-discovery |
| `SENDSPIN_AUDIO_FORMAT` | *(auto)* | Preferred format, e.g. `flac:48000:24:2` |
| `SENDSPIN_STATIC_DELAY_MS` | | Latency compensation in ms |
| `SENDSPIN_CLIENT_ID` | *(auto)* | Unique client ID |
| `SENDSPIN_HOOK_START` | | Command to run when stream starts |
| `SENDSPIN_HOOK_STOP` | | Command to run when stream stops |
| `SENDSPIN_HOOK_SET_VOLUME` | | External volume control script (receives 0–100) |
| `SENDSPIN_LOG_LEVEL` | `INFO` | `DEBUG` `INFO` `WARNING` `ERROR` `CRITICAL` |
| `AUDIO_GID` | `29` | Audio group GID on the host — check with `stat -c '%g' /dev/snd/controlC0` |

---

## List available audio devices

```bash
docker compose run --rm sendspin list-devices
```

---

## Multiple speakers

Run one container per speaker. Each needs a unique `SENDSPIN_AUDIO_DEVICE` and `SENDSPIN_PORT`:

```yaml
services:
  sendspin-office:
    image: ghcr.io/<user>/sendspin-receiver:latest
    network_mode: host
    devices:
      - /dev/snd:/dev/snd
    group_add:
      - "${AUDIO_GID:-29}"
    volumes:
      - sendspin-office-config:/home/sendspin/.config/sendspin
    restart: unless-stopped
    environment:
      SENDSPIN_NAME: "Office"
      SENDSPIN_AUDIO_DEVICE: "0"
      SENDSPIN_PORT: "8927"

  sendspin-living-room:
    image: ghcr.io/<user>/sendspin-receiver:latest
    network_mode: host
    devices:
      - /dev/snd:/dev/snd
    group_add:
      - "${AUDIO_GID:-29}"
    volumes:
      - sendspin-living-room-config:/home/sendspin/.config/sendspin
    restart: unless-stopped
    environment:
      SENDSPIN_NAME: "Living Room"
      SENDSPIN_AUDIO_DEVICE: "1"
      SENDSPIN_PORT: "8928"

volumes:
  sendspin-office-config:
  sendspin-living-room-config:
```

---

## Requirements

- Docker with Compose v2
- Linux host with the USB speaker plugged in before starting the container
- `network_mode: host` — required for mDNS discovery
