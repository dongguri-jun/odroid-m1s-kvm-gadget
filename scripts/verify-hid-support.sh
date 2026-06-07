#!/usr/bin/env bash
set -euo pipefail

status=0

ok() {
  printf 'OK: %s\n' "$1"
}

warn() {
  printf 'WARN: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1"
  status=1
}

have_config_value() {
  local key="$1"
  local expected="$2"
  local config_file="$3"

  grep -Eq "^${key}=${expected}$" "$config_file"
}

is_config_unset() {
  local key="$1"
  local config_file="$2"

  grep -Eq "^# ${key} is not set$" "$config_file"
}

find_kernel_config() {
  local release
  release="$(uname -r)"

  if [[ -r "/boot/config-${release}" ]]; then
    printf '%s\n' "/boot/config-${release}"
    return 0
  fi

  if [[ -r "/proc/config.gz" ]]; then
    printf '%s\n' "/proc/config.gz"
    return 0
  fi

  return 1
}

read_config() {
  local source="$1"
  local target="$2"

  case "$source" in
    *.gz) gzip -dc "$source" > "$target" ;;
    *) cp "$source" "$target" ;;
  esac
}

check_config_enabled_or_module() {
  local key="$1"
  local config_file="$2"

  if have_config_value "$key" "[ym]" "$config_file"; then
    ok "${key} is enabled"
  elif is_config_unset "$key" "$config_file"; then
    fail "${key} is disabled"
  else
    fail "${key} is missing"
  fi
}

check_config_enabled() {
  local key="$1"
  local config_file="$2"

  if have_config_value "$key" "y" "$config_file"; then
    ok "${key}=y"
  elif have_config_value "$key" "m" "$config_file"; then
    fail "${key}=m, but this option is expected built-in"
  elif is_config_unset "$key" "$config_file"; then
    fail "${key} is disabled"
  else
    fail "${key} is missing"
  fi
}

printf 'ODROID M1S HID gadget support verification\n'
printf 'Kernel: %s\n' "$(uname -r)"
printf '\n'

config_source=""
if config_source="$(find_kernel_config)"; then
  tmp_config="$(mktemp)"
  trap 'rm -f "$tmp_config"' EXIT
  read_config "$config_source" "$tmp_config"
  ok "kernel config found at ${config_source}"

  check_config_enabled_or_module CONFIG_USB_GADGET "$tmp_config"
  check_config_enabled_or_module CONFIG_USB_LIBCOMPOSITE "$tmp_config"
  check_config_enabled_or_module CONFIG_USB_CONFIGFS "$tmp_config"
  check_config_enabled CONFIG_USB_CONFIGFS_F_HID "$tmp_config"
  check_config_enabled_or_module CONFIG_USB_F_HID "$tmp_config"

  if have_config_value CONFIG_USB_G_HID "[ym]" "$tmp_config"; then
    ok "CONFIG_USB_G_HID is available for legacy testing"
  else
    warn "CONFIG_USB_G_HID is not available; configfs HID can still be sufficient"
  fi
else
  fail "kernel config not found under /boot/config-$(uname -r) or /proc/config.gz"
fi

printf '\nRuntime checks\n'

if [[ -d /sys/class/udc ]]; then
  udc_count="$(find /sys/class/udc -mindepth 1 -maxdepth 1 -type l -o -type d | wc -l)"
  if [[ "$udc_count" -gt 0 ]]; then
    ok "/sys/class/udc has ${udc_count} controller entry"
    find /sys/class/udc -mindepth 1 -maxdepth 1 -printf 'UDC: %f\n'
  else
    fail "/sys/class/udc exists but no USB device controller is listed"
  fi
else
  fail "/sys/class/udc does not exist"
fi

if [[ -d /sys/kernel/config ]]; then
  ok "/sys/kernel/config exists"
else
  fail "/sys/kernel/config does not exist"
fi

if [[ -d /sys/kernel/config/usb_gadget ]]; then
  ok "/sys/kernel/config/usb_gadget exists"
else
  warn "/sys/kernel/config/usb_gadget is not present; configfs may need to be mounted or CONFIG_USB_CONFIGFS may be disabled"
fi

if command -v modprobe >/dev/null 2>&1; then
  ok "modprobe command is available"
else
  warn "modprobe command is not available"
fi

printf '\nSummary\n'
if [[ "$status" -eq 0 ]]; then
  ok "required HID gadget prerequisites appear available"
else
  fail "required HID gadget prerequisites are not satisfied"
fi

exit "$status"
