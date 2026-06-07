#!/usr/bin/env bash
set -euo pipefail

GADGET_NAME="odroid_m1s_kvm"
GADGET_ROOT="/sys/kernel/config/usb_gadget"

usage() {
  cat <<'EOF'
Usage: teardown-hid-gadget.sh [--gadget-name NAME] [--help]

Safely remove the manual ODROID M1S TinyPilot-compatible USB HID gadget.

Options:
  --gadget-name NAME  Override the configfs gadget directory name.
  --help              Show this help.

Safety rules:
  - Unbind UDC before removing symlinks or functions.
  - Remove only the named gadget.
  - Never use recursive deletion.
EOF
}

info() {
  printf 'INFO: %s\n' "$1"
}

warn() {
  printf 'WARN: %s\n' "$1" >&2
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

parse_args() {
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --help|-h)
        usage
        exit 0
        ;;
      --gadget-name)
        [[ "$#" -ge 2 ]] || die "--gadget-name requires a value"
        GADGET_NAME="$2"
        validate_gadget_name "$GADGET_NAME"
        shift 2
        ;;
      *)
        die "unknown argument: $1"
        ;;
    esac
  done
}

validate_gadget_name() {
  local name="$1"

  [[ -n "$name" ]] || die "gadget name must not be empty"
  [[ "$name" != "." && "$name" != ".." ]] || die "gadget name must not be '.' or '..'"
  [[ "$name" != *"/"* ]] || die "gadget name must not contain path separators"
}

require_root() {
  [[ "$(id -u)" -eq 0 ]] || die "root is required because configfs teardown needs privileged writes"
}

remove_file_or_link_if_exists() {
  local path="$1"

  if [[ -L "$path" || -f "$path" ]]; then
    rm "$path"
    info "removed ${path}"
  else
    info "skip missing file/link ${path}"
  fi
}

remove_dir_if_exists() {
  local path="$1"

  if [[ -d "$path" ]]; then
    rmdir "$path"
    info "removed ${path}"
  else
    info "skip missing directory ${path}"
  fi
}

unbind_udc() {
  local gadget_dir="$1"
  local udc_file="${gadget_dir}/UDC"
  local current_udc=""

  [[ -f "$udc_file" ]] || return 0

  current_udc="$(cat "$udc_file")"
  if [[ -n "$current_udc" ]]; then
    info "unbinding UDC ${current_udc}"
    printf '\n' > "$udc_file"
  else
    info "UDC already unbound"
  fi
}

teardown_gadget() {
  local gadget_dir="$1"

  if [[ ! -d "$gadget_dir" ]]; then
    info "gadget ${gadget_dir} does not exist; nothing to teardown"
    return 0
  fi

  unbind_udc "$gadget_dir"

  remove_file_or_link_if_exists "${gadget_dir}/configs/c.1/hid.usb1"
  remove_file_or_link_if_exists "${gadget_dir}/configs/c.1/hid.usb0"

  remove_dir_if_exists "${gadget_dir}/functions/hid.usb1"
  remove_dir_if_exists "${gadget_dir}/functions/hid.usb0"

  remove_dir_if_exists "${gadget_dir}/configs/c.1/strings/0x409"
  remove_dir_if_exists "${gadget_dir}/configs/c.1"

  remove_dir_if_exists "${gadget_dir}/strings/0x409"
  remove_dir_if_exists "$gadget_dir"
}

main() {
  local gadget_dir

  parse_args "$@"
  validate_gadget_name "$GADGET_NAME"
  require_root

  [[ -d "$GADGET_ROOT" ]] || die "$GADGET_ROOT does not exist; configfs may not be mounted or CONFIG_USB_CONFIGFS may be disabled"

  gadget_dir="${GADGET_ROOT}/${GADGET_NAME}"
  teardown_gadget "$gadget_dir"
  info "teardown complete for ${gadget_dir}"
}

main "$@"
