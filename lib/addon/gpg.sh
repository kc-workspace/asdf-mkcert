#!/usr/bin/env bash

## Check GPG value from input path
## usage: `kc_asdf_gpg '/tmp/hello.tar.gz' 'https://example.com'`
kc_asdf_gpg() {
  local ns="gpg.main"
  local fingerprint=""
  local public_key="${KC_ASDF_RES_PATH:?}/public-key.asc"

  [ -n "${ASDF_INSECURE:-}" ] &&
    kc_asdf_warn "$ns" "Skipped checksum because user disable security" &&
    return 0

  local filepath="$1" gpg_url="$2"
  local dirpath filename
  dirpath="$(dirname "$filepath")"
  filename="$(basename "$filepath")"

  local sig_filepath="$dirpath/$filename.sig"

  ! command -v gpg >/dev/null &&
    kc_asdf_error "$ns" "gpg command is missing" &&
    return 1
  ! [ -f "$public_key" ] &&
    kc_asdf_error "$ns" "public key (%s) is missing" "$public_key" &&
    return 1

  kc_asdf_debug "$ns" "validating public key (%s)" "$public_key"
  if ! kc_asdf_exec gpg --quiet --list-packets "$public_key" | grep -qE "$fingerprint"; then
    kc_asdf_error "$ns" "The public key fingerprint is not matched"
    return 1
  fi

  kc_asdf_debug "$ns" "downloading gpg signature of %s from '%s'" \
    "$filename" "$gpg_url"
  if ! kc_asdf_fetch_file "$gpg_url" "$sig_filepath"; then
    return 1
  fi

  kc_asdf_debug "$ns" "importing public key (%s)" "$public_key"
  if ! kc_asdf_exec gpg --quiet --import "$public_key"; then
    kc_asdf_error "$ns" "import public key failed, look on debug mode for more detail"
    return 1
  fi

  kc_asdf_debug "$ns" "verifying signature of %s" "$filepath"
  if ! gpg --quiet --verify "$sig_filepath" "$filepath"; then
    return 1
  fi

  kc_asdf_debug "$ns" "clean gpg key imported earlier"
  kc_asdf_exec gpg --quiet --yes --batch \
    --delete-secret-and-public-key "$fingerprint"
}
