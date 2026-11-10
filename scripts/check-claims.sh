#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

usage() {
  printf '%s\n' 'usage: scripts/check-claims.sh --repo <dir> --draft <file>' >&2
  exit 2
}

ere() {
  printf '%s' "$1" | sed -e 's/[][\\.^$*+?(){}|]/\\&/g'
}

repo=
draft=
while [ "$#" -gt 0 ]; do
  case $1 in
    --repo|--draft)
      if [ "$#" -lt 2 ]; then usage; fi
      if [ "$1" = --repo ]; then
        if [ -n "$repo" ]; then usage; fi
        repo=$2
      else
        if [ -n "$draft" ]; then usage; fi
        draft=$2
      fi
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done
if [ -z "$repo" ] || [ -z "$draft" ]; then
  usage
fi
if [ ! -d "$repo" ]; then
  printf '%s\n' "fail evidence: $repo is not a directory" >&2
  exit 1
fi
if [ ! -f "$draft" ]; then
  printf '%s\n' "fail claims: $draft is not a file" >&2
  exit 1
fi

has_fence=0
while IFS= read -r line || [ -n "$line" ]; do
  if [ "$line" = '```claims' ]; then
    has_fence=1
    break
  fi
done < "$draft"
if [ "$has_fence" -eq 0 ]; then
  printf '%s\n' 'fail claims: add a claims fence' >&2
  exit 1
fi

draft_text=$(cat "$draft")
bin=$(dirname "$0")
tokens=$(awk -F'`' '{for (i = 2; i <= NF; i += 2) if ($i != "") print $i}' "$draft" | sort -u)
if [ -z "$tokens" ]; then
  printf '%s\n' "ok claims: $draft"
  exit 0
fi

bt='`'

while IFS= read -r token || [ -n "$token" ]; do
  [ -n "$token" ] || continue
  probe=$(sh "$bin/evidence-probe.sh" --repo "$repo" --token "$token")
  config=$(printf '%s\n' "$probe" | sed -n 's/^config: //p')
  history=$(printf '%s\n' "$probe" | sed -n 's/^history: //p')
  while IFS= read -r line || [ -n "$line" ]; do
    [ -n "$line" ] || continue
    if printf '%s\n' "$line" | grep -F -q -- "$token" && printf '%s\n' "$line" | grep -iE "(^|[^[:alnum:]_])ausente([^[:alnum:]_]|$)" >/dev/null; then
      case $config in
        found*)
          printf '%s\n' "fail evidence: $token is in deploy values" >&2
          exit 1
          ;;
      esac
    fi
    if printf '%s\n' "$line" | grep -F -q -- "$bt$token$bt" && printf '%s\n' "$line" | grep -iE "(^|[^[:alnum:]_])(bug|defecto)([^[:alnum:]_]|$)" >/dev/null; then
      subj=${history#found }
      if [ "$history" = absent ] || [ -z "$subj" ] || ! printf '%s\n' "$draft_text" | grep -F -q -- "$subj"; then
        printf '%s\n' 'fail evidence: quote the git log -S subject' >&2
        exit 1
      fi
    fi
  done <<LINE
$draft_text
LINE
done <<EOF
$tokens
EOF
printf '%s\n' "ok claims: $draft"
