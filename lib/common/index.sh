#!/usr/bin/env bash## Environment variables
## https://asdf-vm.com/plugins/create.html#environment-variables-overview

## General information
KC_ASDF_RES_PATH="${KC_ASDF_PLUGIN_PATH:?}/res"
export KC_ASDF_RES_PATH

## Plugin information
KC_ASDF_ORG="kc-workspace"
KC_ASDF_NAME="asdf-mkcert"
KC_ASDF_REPO="https://github.com/kc-workspace/asdf-mkcert"
export KC_ASDF_ORG KC_ASDF_NAME KC_ASDF_REPO

## Application information
KC_ASDF_APP_NAME="mkcert"
KC_ASDF_APP_DESC=""
KC_ASDF_APP_REPO="https://github.com/FiloSottile/mkcert"
export KC_ASDF_APP_NAME KC_ASDF_APP_DESC KC_ASDF_APP_REPO

# shellcheck source-path=SCRIPTDIR/internal.sh
source "${KC_ASDF_PLUGIN_PATH:?}/lib/common/internal.sh" || exit 1
# shellcheck source-path=SCRIPTDIR/defaults.sh
source "${KC_ASDF_PLUGIN_PATH:?}/lib/common/defaults.sh" || exit 1

KC_ASDF_ADDON_LIST=(
  "checksum"
  "download"
  "github"
  "gpg"
  "help"
  "install"
  "system"
  "tags"
  "version"
)
export KC_ASDF_ADDON_LIST

__asdf_load "bin" "${KC_ASDF_ADDON_LIST[@]}"
