#!/bin/bash
set -euo pipefail

TMP=$(getopt -o "o:dvh" -- "$@")
if [ $? -ne 0 ]; then
  exit 1
fi
eval set -- "$TMP"

function warn() {
  echo "WARNING: $1" >&2
}

function log() {
  if [ "$VERBOSE" -eq 1 ]; then
    echo "$1"
  fi
}

DRY_RUN=0
VERBOSE=0
while true; do
  case "$1" in
    '-o')
      readonly EMOJI_DEST=$2
      shift 2
      continue
      ;;
    '-d')
      DRY_RUN=1
      shift
      continue
      ;;
    '-v')
      VERBOSE=1
      shift
      continue
      ;;
    '-h')
      echo "$0 [-o outdir] [-hdv]"
      echo $'\t-h\tDisplay this help'
      echo $'\t-d\tdry-run'
      echo $'\t-v\tverbose'
      exit 0
      ;;
    '--')
      shift
      break
      ;;
    *)
      warn "Unknown argument '$1', ignoring..."
      shift
      continue
      ;;
  esac
done

if [ -z "$(command -v convert)" ]; then
  echo "Need imagemagick installed!" >&2
  exit 1
fi

if ! [ -v EMOJI_DEST ]; then
  readonly EMOJI_DEST=~/.local/share/custom-emojis.nvim
fi
log "Using output dir '$EMOJI_DEST'"

readonly EMOJI_PACKS=("https://strapi.volpeon.ink/uploads/drgn_d23daa833a.zip" "https://strapi.volpeon.ink/uploads/wvrn_16ac23f779.zip" "https://strapi.volpeon.ink/uploads/neofox_e17e757433.zip")
log $EMOJI_PACKS

mkdir -p "$EMOJI_DEST"
for pack in "${EMOJI_PACKS[@]}"; do
  pack_path="/tmp/${pack##*/}"
  unzipped_pack_path="${pack_path%.*}"
  
  log "Downloading $pack to $pack_path"
  if [ $DRY_RUN -ne 1 ]; then
    curl "$pack" -o "$pack_path"
  fi
  
  log "Extracting to $unzipped_pack_path"
  if [ $DRY_RUN -ne 1 ]; then
    unzip -qn "$pack_path" -d "$unzipped_pack_path"
  fi
  for img in $unzipped_pack_path/*.png; do 
    log "converting $img..."
    if [ $DRY_RUN -ne 1 ]; then
      magick "$img" -resize 32X32 "$EMOJI_DEST/${img##*/}"
    fi
  done

  # cleanup
  log "Running Cleanup..."
  if [ $DRY_RUN -ne 1 ]; then
    rm "$pack_path"
    rm -rf "$unzipped_pack_path"
  fi
done
