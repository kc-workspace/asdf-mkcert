#!/usr/bin/env bash

## Check shasum of input path
## usage: `kc_asdf_checksum '/tmp/hello.tar.gz' 'https://example.com'`
## variables:
##   - ASDF_INSECURE for disable checksum verify
kc_asdf_checksum() {
  local ns="checksum.main"
  local filepath="$1" cs_url="$2"

  [ -n "${ASDF_INSECURE:-}" ] &&
    kc_asdf_warn "$ns" "Skipped checksum because user disable security" &&
    return 0

  local cs_tmp="checksum.tmp" cs_txt="checksum.txt"
  local dirpath filename
  dirpath="$(dirname "$filepath")"
  filename="$(basename "$filepath")"

  local cs_tmppath="$dirpath/$cs_tmp" cs_path="$dirpath/$cs_txt"

  kc_asdf_debug "$ns" "downloading checksum of %s from '%s'" \
    "$filename" "$cs_url"
  if ! kc_asdf_fetch_file "$cs_url" "$cs_tmppath"; then
    return 1
  fi

  kc_asdf_debug "$ns" "modifying checksum '%s' to '%s'" \
    "$cs_tmppath" "$cs_path"
  if command -v _kc_asdf_custom_checksum >/dev/null; then
    kc_asdf_debug "$ns" "use custom function to update checksum file"
    _kc_asdf_custom_checksum "$filename" "$cs_tmppath" "$cs_path"
  else
    if ! grep "$filename" "$cs_tmppath" >"$cs_path"; then
      kc_asdf_error "$ns" "missing %s on checksum file (%s)" \
        "$filename" "$cs_tmppath"
      return 1
    fi
  fi

  local cs_algorithm=""
  local shasum="sha${cs_algorithm}sum"
  command -v "$shasum" >/dev/null ||
    shasum="shasum"

  local tmp="$PWD"
  cd "$dirpath" &&
    kc_asdf_exec "$shasum" --check "$cs_txt" >/dev/null &&
    cd "$tmp" || return 1
}
