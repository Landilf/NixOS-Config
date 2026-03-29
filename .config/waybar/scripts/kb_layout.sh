#!/usr/bin/env bash
set -euo pipefail

WAYBAR_SIGNAL="${WAYBAR_SIGNAL:-9}"
PREFERRED_DEVICE="${WAYBAR_KB_DEVICE:-}"
EN_INDEX="${WAYBAR_KB_EN_INDEX:-0}"
RU_INDEX="${WAYBAR_KB_RU_INDEX:-1}"

have() { command -v "$1" >/dev/null 2>&1; }

is_ru() { [[ "${1,,}" == *russian* || "${1,,}" == *ru* ]]; }
is_en() { [[ "${1,,}" == *english* || "${1,,}" == *us* || "${1,,}" == *en* ]]; }

jq_ok() {
  have jq || return 1
  jq -e . >/dev/null 2>&1 <<<"${1:-}"
}

usage() {
  cat >&2 <<'EOF'
Usage:
  kb_layout.sh                Print current layout (Waybar)
  kb_layout.sh --toggle       Toggle layout, then print current layout
  kb_layout.sh --watch        Stream updates on layout change (Waybar)

Env:
  WAYBAR_KB_DEVICE      Prefer specific Hyprland keyboard device name
  WAYBAR_KB_EN_INDEX    Layout index for EN (default: 0)
  WAYBAR_KB_RU_INDEX    Layout index for RU (default: 1)
  WAYBAR_SIGNAL         SIGRTMIN+N to poke Waybar on --toggle (default: 9)
EOF
}

pick_device() {
  local devices_json="$1"

  if [[ -n "$PREFERRED_DEVICE" ]]; then
    printf '%s\n' "$PREFERRED_DEVICE"
    return 0
  fi

  if jq_ok "$devices_json"; then
    local main
    main="$(jq -r '.keyboards[]? | select(.main == true) | .name' <<<"$devices_json" 2>/dev/null | head -n1 || true)"
    if [[ -n "$main" && "$main" != "null" ]]; then
      printf '%s\n' "$main"
      return 0
    fi

    jq -r '.keyboards[0]?.name // empty' <<<"$devices_json" 2>/dev/null | head -n1 || true
    return 0
  fi

  # Best-effort fallback without jq.
  printf '%s\n' "$devices_json" | sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1 || true
}

active_keymap() {
  local devices_json="$1"
  local device_name="$2"

  if jq_ok "$devices_json"; then
    jq -r --arg name "$device_name" '.keyboards[]? | select(.name == $name) | (.active_keymap // empty)' \
      <<<"$devices_json" 2>/dev/null | head -n1 || true
    return 0
  fi

  # Best-effort fallback without jq.
  printf '%s\n' "$devices_json" | sed -n 's/.*"active_keymap"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1 || true
}

socket2_path() {
  local runtime="${XDG_RUNTIME_DIR:-}"
  if [[ -z "$runtime" ]]; then
    runtime="/run/user/$(id -u)"
  fi

  if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    return 1
  fi

  printf '%s\n' "$runtime/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
}

watch_events() {
  local sock
  sock="$(socket2_path)" || return 1
  [[ -S "$sock" ]] || return 1

  if have socat; then
    socat -u "UNIX-CONNECT:$sock" - 2>/dev/null
    return $?
  fi

  if have nc; then
    nc -U "$sock" 2>/dev/null
    return $?
  fi

  return 1
}

can_watch_events() {
  local sock
  sock="$(socket2_path)" || return 1
  [[ -S "$sock" ]] || return 1
  have socat || have nc
}

print_status() {
  if ! have hyprctl; then
    echo " --"
    return 0
  fi

  local devices_json device keymap abbr
  devices_json="$(hyprctl -j devices 2>/dev/null || true)"
  device="$(pick_device "$devices_json")"
  if [[ -z "$device" ]]; then
    echo " --"
    return 0
  fi

  keymap="$(active_keymap "$devices_json" "$device")"

  if [[ -z "$keymap" ]]; then
    abbr="--"
  elif is_ru "$keymap"; then
    abbr="RU"
  elif is_en "$keymap"; then
    abbr="EN"
  else
    abbr="--"
  fi

  echo " $abbr"
}

toggle_layout() {
  if ! have hyprctl; then
    return 0
  fi

  local devices_json device keymap
  devices_json="$(hyprctl -j devices 2>/dev/null || true)"
  device="$(pick_device "$devices_json")"
  [[ -n "$device" ]] || return 0
  keymap="$(active_keymap "$devices_json" "$device")"

  if is_ru "$keymap"; then
    hyprctl switchxkblayout "$device" "$EN_INDEX" >/dev/null 2>&1 || hyprctl switchxkblayout "$device" next >/dev/null 2>&1 || true
  elif is_en "$keymap"; then
    hyprctl switchxkblayout "$device" "$RU_INDEX" >/dev/null 2>&1 || hyprctl switchxkblayout "$device" next >/dev/null 2>&1 || true
  else
    hyprctl switchxkblayout "$device" next >/dev/null 2>&1 || true
  fi

  pkill -SIGRTMIN+"$WAYBAR_SIGNAL" -x waybar 2>/dev/null || true
}

case "${1:-}" in
  ""|--toggle|--watch) ;;
  -h|--help) usage; exit 0 ;;
  *) usage; exit 2 ;;
esac

if [[ "${1:-}" == "--watch" ]]; then
  print_status

  set +e
  if can_watch_events; then
    while true; do
      while IFS= read -r line; do
        case "$line" in
          activelayout*'>>'*|activelayoutv2*'>>'*)
            print_status
            ;;
        esac
      done < <(watch_events)
      sleep 0.2
    done
  else
    while sleep 1; do
      print_status
    done
  fi
  exit 0
fi

if [[ "${1:-}" == "--toggle" ]]; then
  toggle_layout
fi

print_status
