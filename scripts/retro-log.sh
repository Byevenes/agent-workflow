#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

tab=$(printf '\t')
force=0

usage() {
  echo "usage: scripts/retro-log.sh begin --path <rel> | seal <id> --error <text> | pending | confirm <id> | revert [--force] <id>" >&2
  exit 2
}

die() {
  printf 'retro-log: %s\n' "$1" >&2
  exit "$2"
}

has_break() {
  case $1 in
    *"$tab"*) return 0 ;;
  esac
  before=$(printf '%s' "$1" | wc -c)
  after=$(printf '%s' "$1" | tr -d '\n' | wc -c)
  [ "$before" != "$after" ]
}

valid_id() {
  case $1 in
    ''|*[!0-9]*|0*) return 1 ;;
    *) return 0 ;;
  esac
}

valid_path() {
  p=$1
  [ -n "$p" ] || return 1
  case $p in
    /*|~*|*/) return 1 ;;
  esac
  case $p in
    *\\*) return 1 ;;
  esac
  case $p in
    .scratch|.scratch/*) return 1 ;;
  esac
  rest=$p
  while [ -n "$rest" ]; do
    seg=${rest%%/*}
    [ -n "$seg" ] || return 1
    [ "$seg" != "." ] || return 1
    [ "$seg" != ".." ] || return 1
    case $rest in
      */*) rest=${rest#*/} ;;
      *) rest= ;;
    esac
  done
  return 0
}

if [ -n "${RETRO_ROOT:-}" ]; then
  root=$RETRO_ROOT
else
  root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi
scratch=$root/.scratch
log=$scratch/retro-log.tsv
opend=$scratch/retro-open
snapd=$scratch/retro-snapshots

next_id() {
  max=0
  if [ -f "$log" ]; then
    m=$(awk -F '\t' 'BEGIN { m = 0 } $1 ~ /^[1-9][0-9]*$/ && $1 + 0 > m { m = $1 + 0 } END { print m + 0 }' "$log")
    if [ "$m" -gt "$max" ]; then
      max=$m
    fi
  fi
  if [ -d "$opend" ]; then
    for f in "$opend"/*; do
      [ -e "$f" ] || continue
      base=${f##*/}
      case $base in
        *.path) continue ;;
        *.missing) base=${base%.missing} ;;
      esac
      case $base in
        *[!0-9]*|0*) continue ;;
      esac
      if [ "$base" -gt "$max" ]; then
        max=$base
      fi
    done
  fi
  printf '%s\n' "$((max + 1))"
}

field() {
  awk -F '\t' -v id="$id" -v col="$1" '$1 == id { print $col; exit }' "$log"
}

set_state() {
  newstate=$1
  tmp=$(mktemp)
  awk -F '\t' -v id="$id" -v st="$newstate" 'BEGIN { OFS = "\t" } $1 == id { $3 = st } { print }' "$log" > "$tmp"
  mv "$tmp" "$log"
}

load_fp() {
  fp_file=$1
  fp_mode=$2
  if [ ! -e "$fp_file" ] && [ ! -L "$fp_file" ]; then
    FP_CRC=missing
    FP_BYTES=0
    return 0
  fi
  if [ -d "$fp_file" ]; then
    if [ "$fp_mode" = seal ]; then
      die "bad path" 2
    fi
    FP_CRC=directory
    FP_BYTES=0
    return 0
  fi
  ck=$(cksum "$fp_file")
  FP_CRC=${ck%% *}
  rest=${ck#* }
  FP_BYTES=${rest%% *}
}

find_saved() {
  if [ -f "$snapd/$id" ]; then
    SAVED_KIND=bytes
    SAVED_FILE=$snapd/$id
    return 0
  fi
  if [ -f "$opend/$id" ]; then
    SAVED_KIND=bytes
    SAVED_FILE=$opend/$id
    return 0
  fi
  if [ -f "$snapd/$id.missing" ]; then
    SAVED_KIND=missing
    SAVED_FILE=$snapd/$id.missing
    return 0
  fi
  if [ -f "$opend/$id.missing" ]; then
    SAVED_KIND=missing
    SAVED_FILE=$opend/$id.missing
    return 0
  fi
  SAVED_KIND=none
  SAVED_FILE=
}

require_pendiente() {
  [ -f "$log" ] || die "unknown id" 1
  state=$(field 3)
  [ -n "$state" ] || die "unknown id" 1
  [ "$state" = pendiente ] || die "not pendiente" 1
}

do_begin() {
  if has_break "$path"; then
    die "bad field" 2
  fi
  if ! valid_path "$path"; then
    die "bad path" 2
  fi
  file=$root/$path
  if [ -e "$file" ] || [ -L "$file" ]; then
    if [ -d "$file" ]; then
      die "bad path" 2
    fi
  fi
  id=$(next_id)
  mkdir -p "$opend"
  if [ -e "$file" ]; then
    cp "$file" "$opend/$id"
  else
    printf '' > "$opend/$id.missing"
  fi
  printf '%s\n' "$path" > "$opend/$id.path"
  printf '%s\n' "$id"
}

do_seal() {
  if ! valid_id "$id"; then
    die "bad id" 2
  fi
  if [ -z "$err" ] || has_break "$err"; then
    die "bad field" 2
  fi
  pathfile=$opend/$id.path
  [ -f "$pathfile" ] || die "not open" 1
  IFS= read -r path < "$pathfile" || die "not open" 1
  if has_break "$path" || ! valid_path "$path"; then
    die "bad path" 2
  fi
  if [ -f "$log" ]; then
    existing=$(awk -F '\t' -v id="$id" '$1 == id { print $1; exit }' "$log")
    if [ -n "$existing" ]; then
      die "already sealed" 1
    fi
  fi
  if [ -f "$opend/$id.missing" ]; then
    kind=missing
  elif [ -f "$opend/$id" ]; then
    kind=bytes
  else
    die "not open" 1
  fi
  load_fp "$root/$path" seal
  if [ -n "${RETRO_DATE:-}" ]; then
    today=$RETRO_DATE
  else
    today=$(date +%Y-%m-%d)
  fi
  case $today in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *) die "bad date" 2 ;;
  esac
  if has_break "$today"; then
    die "bad field" 2
  fi
  mkdir -p "$scratch" "$snapd"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$id" "$today" pendiente "$FP_CRC" "$FP_BYTES" "$err" "$path" >> "$log"
  if [ "$kind" = missing ]; then
    mv "$opend/$id.missing" "$snapd/$id.missing"
  else
    mv "$opend/$id" "$snapd/$id"
  fi
  rm -f "$pathfile"
}

do_pending() {
  if [ ! -f "$log" ]; then
    exit 0
  fi
  awk -F '\t' '$3 == "pendiente" { print }' "$log"
}

do_confirm() {
  if ! valid_id "$id"; then
    die "bad id" 2
  fi
  require_pendiente
  set_state confirmado
  rm -f "$snapd/$id" "$snapd/$id.missing" "$opend/$id" "$opend/$id.missing" "$opend/$id.path"
  printf '%s\n' "$id"
}

do_revert() {
  if ! valid_id "$id"; then
    die "bad id" 2
  fi
  require_pendiente
  crc=$(field 4)
  bytes=$(field 5)
  path=$(field 7)
  if has_break "$path" || ! valid_path "$path"; then
    die "bad path" 2
  fi
  find_saved
  if [ "$SAVED_KIND" = none ]; then
    set_state revertido
    printf '%s\n' "$id"
    printf '%s\n' marked-only
    return 0
  fi
  file=$root/$path
  load_fp "$file" revert
  if [ "$force" -eq 0 ] && { [ "$FP_CRC" != "$crc" ] || [ "$FP_BYTES" != "$bytes" ]; }; then
    printf '%s\n' dirty
    exit 3
  fi
  if [ -d "$file" ] && [ ! -L "$file" ]; then
    die "bad path" 2
  fi
  if [ "$SAVED_KIND" = missing ]; then
    if [ -e "$file" ] || [ -L "$file" ]; then
      rm -f "$file"
    fi
  else
    dir=$(dirname "$file")
    mkdir -p "$dir"
    tmp=$(mktemp "$dir/.retro-restore.XXXXXX")
    if ! cat "$SAVED_FILE" > "$tmp"; then
      rm -f "$tmp"
      die "restore failed" 1
    fi
    mv -f "$tmp" "$file"
  fi
  set_state revertido
  printf '%s\n' "$id"
  printf '%s\n' restored
}

[ "$#" -ge 1 ] || usage
cmd=$1
shift
case $cmd in
  begin)
    [ "$#" -eq 2 ] && [ "$1" = "--path" ] || usage
    path=$2
    do_begin
    ;;
  seal)
    [ "$#" -eq 3 ] && [ "$2" = "--error" ] || usage
    id=$1
    err=$3
    do_seal
    ;;
  pending)
    [ "$#" -eq 0 ] || usage
    do_pending
    ;;
  confirm)
    [ "$#" -eq 1 ] || usage
    id=$1
    do_confirm
    ;;
  revert)
    if [ "$#" -eq 2 ] && [ "$1" = "--force" ]; then
      force=1
      id=$2
    elif [ "$#" -eq 1 ]; then
      id=$1
    else
      usage
    fi
    do_revert
    ;;
  *)
    usage
    ;;
esac
