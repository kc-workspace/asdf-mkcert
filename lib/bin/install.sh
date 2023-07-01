#!/usr/bin/env bash

__kc_asdf_is_ref() {
  [[ "${ASDF_INSTALL_TYPE:?}" == "ref" ]]
}
__kc_asdf_is_ver() {
  [[ "${ASDF_INSTALL_TYPE:?}" == "version" ]]
}

__asdf_bin() {
  # shellcheck disable=SC2034
  local ns="$1"
  shift

  local type="${ASDF_INSTALL_TYPE:?}"
  local version="${ASDF_INSTALL_VERSION:?}"
  local indir="${ASDF_DOWNLOAD_PATH:?}"
  local outdir="${ASDF_INSTALL_PATH:?}"
  local concurrency="${ASDF_CONCURRENCY:-1}"

  kc_asdf_debug "$ns" "installing %s %s %s" \
    "$KC_ASDF_APP_NAME" "$type" "$version"
  kc_asdf_debug "$ns" "download location is %s" "$indir"
  kc_asdf_debug "$ns" "install location is %s" "$outdir"

  if __kc_asdf_is_ref; then
    if command -v _kc_asdf_custom_source_build >/dev/null; then
      local tmp="$PWD"
      cd "$indir" || return 1
      kc_asdf_step "build" "$outdir" \
        _kc_asdf_custom_source_build \
        "$version" "$outdir" "$concurrency" ||
        return 1
      cd "$tmp" || return 1
    else
      kc_asdf_error "$ns" "%s missing, please create issue on repository" \
        "_kc_asdf_custom_source_build()"
      return 1
    fi
  elif __kc_asdf_is_ver; then
    kc_asdf_step "install" "$outdir" \
      kc_asdf_transfer 'copy' "$indir" "$outdir" ||
      return 1
    ## Transfer files recording install mapping
    local vars install_map
    install_map=(
      "mkcert:bin/mkcert"
    )
    vars=("os=$KC_ASDF_OS" "arch=$KC_ASDF_ARCH" "version=$version")
    local transfer_method="move"
    local raw key value
    for raw in "${install_map[@]}"; do
      key="$(kc_asdf_template "${raw%%:*}" "${vars[@]}")"
      value="$(kc_asdf_template "${raw##*:}" "${vars[@]}")"
      kc_asdf_step "$transfer_method" "$key -> $value" \
        kc_asdf_transfer "$transfer_method" "$outdir/$key" "$outdir/$value"
    done
  fi

  ## Chmod all bin files
  local bin bins=(bin)
  local file outpath
  for bin in "${bins[@]}"; do
    outpath="$outdir/$bin"
    [ -d "$outpath" ] ||
      continue

    kc_asdf_debug "$ns" "running chmod all files in %s" \
      "$outpath"
    for file in "$outpath"/*; do
      [ -f "$file" ] &&
        kc_asdf_exec chmod +x "$file"
    done
  done

  # shellcheck disable=SC2011
  kc_asdf_debug "$ns" "list '%s': [%s]" \
    "$outdir" "$(ls "$outdir" | xargs echo)"
  for bin in "${bins[@]}"; do
      outpath="$outdir/$bin"
    if kc_asdf_present_dir "$outpath"; then
      # shellcheck disable=SC2011
      kc_asdf_debug "$ns" "list '%s': [%s]" \
        "$bin" "$(ls "$outpath" | xargs echo)"
    else
      kc_asdf_error "$ns" "%s contains no executable file" \
        "$outpath"
      return 1
    fi
  done
}
