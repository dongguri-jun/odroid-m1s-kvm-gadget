#!/usr/bin/env bash
set -euo pipefail

GADGET_NAME="odroid_m1s_kvm"
GADGET_ROOT="/sys/kernel/config/usb_gadget"
UDC_NAME=""
FORCE=0

usage() {
  cat <<'EOF'
Usage: setup-hid-gadget.sh [--udc NAME] [--force] [--gadget-name NAME] [--help]

Create a manual TinyPilot-compatible ODROID M1S USB HID gadget.

Options:
  --udc NAME          Bind to a specific UDC from /sys/class/udc.
  --force             Remove an existing unbound gadget with the same name first.
                      This never uses recursive deletion and refuses bound gadgets.
  --gadget-name NAME  Override the configfs gadget directory name.
  --help              Show this help.

Expected outputs after a successful bind:
  /dev/hidg0  keyboard, report_length=8
  /dev/hidg1  mouse, report_length=7
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
      --force)
        FORCE=1
        shift
        ;;
      --udc)
        [[ "$#" -ge 2 ]] || die "--udc requires a value"
        UDC_NAME="$2"
        shift 2
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
  [[ "$(id -u)" -eq 0 ]] || die "root is required because configfs and UDC binding need privileged writes"
}

load_modules() {
  if ! command -v modprobe >/dev/null 2>&1; then
    warn "modprobe is unavailable; continuing with currently loaded kernel modules"
    return 0
  fi

  modprobe libcomposite || die "failed to load libcomposite"

  # On modular kernels, this may pre-load the HID function. Built-in kernels may
  # not expose a module by this name, so failure here is only informational.
  if ! modprobe usb_f_hid >/dev/null 2>&1; then
    warn "usb_f_hid module did not load; it may be built in or HID configfs support may be missing"
  fi
}

ensure_configfs() {
  [[ -d /sys/kernel/config ]] || die "/sys/kernel/config does not exist"

  if [[ ! -d "$GADGET_ROOT" ]] && command -v mount >/dev/null 2>&1; then
    info "attempting to mount configfs at /sys/kernel/config"
    mount -t configfs none /sys/kernel/config 2>/dev/null || true
  fi

  [[ -d "$GADGET_ROOT" ]] || die "$GADGET_ROOT does not exist; check CONFIG_USB_CONFIGFS and configfs mount state"
}

list_udcs() {
  local udc

  [[ -d /sys/class/udc ]] || return 0

  for udc in /sys/class/udc/*; do
    [[ -e "$udc" ]] || continue
    basename "$udc"
  done
}

select_udc() {
  local count

  [[ -d /sys/class/udc ]] || die "/sys/class/udc does not exist"

  if [[ -n "$UDC_NAME" ]]; then
    [[ -e "/sys/class/udc/${UDC_NAME}" ]] || die "requested UDC '${UDC_NAME}' does not exist under /sys/class/udc"
    printf '%s\n' "$UDC_NAME"
    return 0
  fi

  mapfile -t udcs < <(list_udcs)
  count="${#udcs[@]}"

  case "$count" in
    0)
      die "no UDC found under /sys/class/udc; check OTG cable, USB role, DTB, and kernel gadget support"
      ;;
    1)
      printf '%s\n' "${udcs[0]}"
      ;;
    *)
      printf 'Available UDCs:\n' >&2
      printf '  %s\n' "${udcs[@]}" >&2
      die "multiple UDCs found; rerun with --udc NAME"
      ;;
  esac
}

remove_path_if_exists() {
  local path="$1"

  if [[ -L "$path" || -f "$path" ]]; then
    rm "$path"
  elif [[ -d "$path" ]]; then
    rmdir "$path"
  fi
}

remove_unbound_existing_gadget() {
  local gadget_dir="$1"
  local udc_file="${gadget_dir}/UDC"
  local current_udc=""

  [[ -d "$gadget_dir" ]] || return 0

  if [[ -f "$udc_file" ]]; then
    current_udc="$(cat "$udc_file")"
    if [[ -n "$current_udc" ]]; then
      die "existing gadget '${gadget_dir}' is bound to '${current_udc}'; run teardown first instead of --force"
    fi
  fi

  [[ "$FORCE" -eq 1 ]] || die "gadget '${gadget_dir}' already exists; use teardown or rerun with --force if it is stale and unbound"

  warn "removing stale unbound gadget '${gadget_dir}' without recursive deletion"
  remove_path_if_exists "${gadget_dir}/configs/c.1/hid.usb1"
  remove_path_if_exists "${gadget_dir}/configs/c.1/hid.usb0"
  remove_path_if_exists "${gadget_dir}/configs/c.1/strings/0x409"
  remove_path_if_exists "${gadget_dir}/configs/c.1"
  remove_path_if_exists "${gadget_dir}/functions/hid.usb1"
  remove_path_if_exists "${gadget_dir}/functions/hid.usb0"
  remove_path_if_exists "${gadget_dir}/strings/0x409"
  remove_path_if_exists "$gadget_dir"
}

write_keyboard_descriptor() {
  local path="$1"

  {
    printf '\x05\x01\x09\x06\xA1\x01\x05\x08'
    printf '\x19\x01\x29\x03\x15\x00\x25\x01'
    printf '\x75\x01\x95\x03\x91\x02\x09\x4B'
    printf '\x95\x01\x91\x02\x95\x04\x91\x01'
    printf '\x05\x07\x19\xE0\x29\xE7\x95\x08'
    printf '\x81\x02\x75\x08\x95\x01\x81\x01'
    printf '\x19\x00\x29\x91\x26\xFF\x00\x95'
    printf '\x06\x81\x00\xC0'
  } > "$path"
}

write_mouse_descriptor() {
  local path="$1"

  {
    printf '\x05\x01\x09\x02\xA1\x01\x05\x09'
    printf '\x19\x01\x29\x08\x15\x00\x25\x01'
    printf '\x95\x08\x75\x01\x81\x02\x05\x01'
    printf '\x09\x30\x09\x31\x16\x00\x00\x26'
    printf '\xFF\x7F\x75\x10\x95\x02\x81\x02'
    printf '\x09\x38\x15\x81\x25\x7F\x75\x08'
    printf '\x95\x01\x81\x06\x05\x0C\x0A\x38'
    printf '\x02\x15\x81\x25\x7F\x75\x08\x95'
    printf '\x01\x81\x06\xC0'
  } > "$path"
}

create_gadget() {
  local gadget_dir="$1"
  local config_dir="${gadget_dir}/configs/c.1"
  local keyboard_dir="${gadget_dir}/functions/hid.usb0"
  local mouse_dir="${gadget_dir}/functions/hid.usb1"

  mkdir "$gadget_dir"

  printf '0x1d6b\n' > "${gadget_dir}/idVendor"
  printf '0x0104\n' > "${gadget_dir}/idProduct"
  printf '0x0100\n' > "${gadget_dir}/bcdDevice"
  printf '0x0200\n' > "${gadget_dir}/bcdUSB"

  mkdir -p "${gadget_dir}/strings/0x409"
  printf 'odroid-m1s-kvm-gadget\n' > "${gadget_dir}/strings/0x409/serialnumber"
  printf 'odroid-m1s-kvm-gadget\n' > "${gadget_dir}/strings/0x409/manufacturer"
  printf 'ODROID M1S TinyPilot-Compatible KVM Gadget\n' > "${gadget_dir}/strings/0x409/product"

  mkdir "$keyboard_dir" || die "failed to create keyboard HID function; check CONFIG_USB_CONFIGFS_F_HID and CONFIG_USB_F_HID"
  printf '1\n' > "${keyboard_dir}/protocol"
  printf '1\n' > "${keyboard_dir}/subclass"
  printf '8\n' > "${keyboard_dir}/report_length"
  write_keyboard_descriptor "${keyboard_dir}/report_desc"
  if [[ -f "${keyboard_dir}/no_out_endpoint" ]]; then
    printf '1\n' > "${keyboard_dir}/no_out_endpoint"
  fi

  mkdir "$mouse_dir" || die "failed to create mouse HID function; check CONFIG_USB_CONFIGFS_F_HID and CONFIG_USB_F_HID"
  printf '0\n' > "${mouse_dir}/protocol"
  printf '0\n' > "${mouse_dir}/subclass"
  printf '7\n' > "${mouse_dir}/report_length"
  write_mouse_descriptor "${mouse_dir}/report_desc"

  mkdir -p "${config_dir}/strings/0x409"
  printf '250\n' > "${config_dir}/MaxPower"
  printf 'HID keyboard and mouse\n' > "${config_dir}/strings/0x409/configuration"

  ln -s "$keyboard_dir" "${config_dir}/hid.usb0"
  ln -s "$mouse_dir" "${config_dir}/hid.usb1"
}

bind_gadget() {
  local gadget_dir="$1"
  local udc_name="$2"

  printf '%s\n' "$udc_name" > "${gadget_dir}/UDC"
}

verify_bound_gadget() {
  local gadget_dir="$1"
  local bound_udc

  bound_udc="$(cat "${gadget_dir}/UDC")"
  [[ -n "$bound_udc" ]] || die "gadget UDC file is empty after bind"
  [[ -e /dev/hidg0 ]] || die "/dev/hidg0 was not created after bind"
  [[ -e /dev/hidg1 ]] || die "/dev/hidg1 was not created after bind"

  info "bound to UDC: ${bound_udc}"
  info "keyboard node: $(ls -l /dev/hidg0)"
  info "mouse node: $(ls -l /dev/hidg1)"
}

main() {
  local gadget_dir
  local selected_udc

  parse_args "$@"
  validate_gadget_name "$GADGET_NAME"
  require_root
  load_modules
  ensure_configfs

  gadget_dir="${GADGET_ROOT}/${GADGET_NAME}"
  remove_unbound_existing_gadget "$gadget_dir"

  selected_udc="$(select_udc)"
  info "selected UDC: ${selected_udc}"

  create_gadget "$gadget_dir"
  bind_gadget "$gadget_dir" "$selected_udc"
  verify_bound_gadget "$gadget_dir"

  info "created TinyPilot-compatible HID gadget"
}

main "$@"
