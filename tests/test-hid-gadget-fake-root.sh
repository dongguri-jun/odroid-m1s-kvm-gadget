#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d /tmp/odroid-m1s-kvm-fake-root.XXXXXX)"

cleanup() {
  rm -rf "$test_root"
}
trap cleanup EXIT

mkdir -p "${test_root}/sys/class/udc"
: > "${test_root}/sys/class/udc/fake_udc"

"${repo_root}/scripts/setup-hid-gadget.sh" --test-root "$test_root" --udc fake_udc > "${test_root}/setup.log"

gadget_dir="${test_root}/sys/kernel/config/usb_gadget/odroid_m1s_kvm"

test -e "${test_root}/dev/hidg0"
test -e "${test_root}/dev/hidg1"
grep -q '^fake_udc$' "${gadget_dir}/UDC"
grep -q '^8$' "${gadget_dir}/functions/hid.usb0/report_length"
grep -q '^7$' "${gadget_dir}/functions/hid.usb1/report_length"
test -L "${gadget_dir}/configs/c.1/hid.usb0"
test -L "${gadget_dir}/configs/c.1/hid.usb1"

"${repo_root}/scripts/teardown-hid-gadget.sh" --test-root "$test_root" > "${test_root}/teardown.log"

test ! -e "$gadget_dir"
test ! -e "${test_root}/dev/hidg0"
test ! -e "${test_root}/dev/hidg1"

printf 'fake-root HID gadget setup/teardown test passed\n'
