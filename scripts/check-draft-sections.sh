#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

sections_for() {
  case $1 in
    analysis)
      printf '%s\n' '## Context' '## Findings' '## Uncertainties' '## Sources'
      ;;
    questionnaire)
      printf '%s\n' '## Questions' '## Priority' '## Blocking'
      ;;
    techspec)
      printf '%s\n' \
        '## Contexto y alcance' \
        '## Límites y supuestos' \
        '## Definiciones' \
        '## Reglas de negocio técnicas' \
        '## Arquitectura' \
        '## Modelo de datos y cambios de BD' \
        '## Contratos y APIs' \
        '## Errores y reintentos' \
        '## Seguridad' \
        '## Atributos de calidad' \
        '## Ambientes y despliegue' \
        '## Plan de pruebas' \
        '## Criterios de verificación técnicos' \
        '## Pendientes' \
        '## Registro de cambios'
      ;;
    delivery-note)
      printf '%s\n' '## Qué cambió' '## Cómo verificar' '## Riesgos o confirmaciones pendientes'
      ;;
    ticket-comment)
      printf '%s\n' '## Requirement' '## Evidence' '## Open'
      ;;
    *)
      printf '%s\n' "usage: scripts/check-draft-sections.sh <kind> <draft>" >&2
      printf '%s\n' "kind: analysis, questionnaire, techspec, delivery-note, ticket-comment" >&2
      return 2
      ;;
  esac
}

check_file() {
  kind=$1
  file=$2
  if [ ! -f "$file" ]; then
    printf '%s\n' "fail: not a file: $file" >&2
    return 1
  fi
  missing=0
  headings=$(sections_for "$kind") || return $?
  while IFS= read -r heading || [ -n "$heading" ]; do
    [ -n "$heading" ] || continue
    if ! grep -qF -- "$heading" "$file"; then
      printf '%s\n' "fail $kind: missing $heading" >&2
      missing=1
    fi
  done <<EOF
$headings
EOF
  return "$missing"
}

known_kind() {
  case $1 in
    analysis|questionnaire|techspec|delivery-note|ticket-comment) return 0 ;;
    *) return 1 ;;
  esac
}

check_example() {
  ex=$1
  if [ ! -f "$ex" ]; then
    printf '%s\n' "fail: not a file: $ex" >&2
    return 1
  fi
  root=$(mktemp -d)
  trap 'rm -rf "$root"' EXIT
  kind=
  part=
  while IFS= read -r line || [ -n "$line" ]; do
    case $line in
      '<!-- doc: '*' -->')
        kind=${line#<!-- doc: }
        kind=${kind% -->}
        if ! known_kind "$kind"; then
          printf '%s\n' "fail example: unknown kind: $kind" >&2
          return 1
        fi
        mkdir -p "$root/$kind"
        : > "$root/$kind/before.md"
        : > "$root/$kind/after.md"
        : > "$root/$kind/facts"
        : > "$root/$kind/fillers"
        part=
        ;;
      '<!-- before -->')
        part=before
        ;;
      '<!-- after -->')
        part=after
        ;;
      '<!-- fact: '*' -->')
        if [ -z "$kind" ]; then
          printf '%s\n' "fail example: fact before a document" >&2
          return 1
        fi
        item=${line#<!-- fact: }
        item=${item% -->}
        printf '%s\n' "$item" >> "$root/$kind/facts"
        ;;
      '<!-- filler: '*' -->')
        if [ -z "$kind" ]; then
          printf '%s\n' "fail example: filler before a document" >&2
          return 1
        fi
        item=${line#<!-- filler: }
        item=${item% -->}
        printf '%s\n' "$item" >> "$root/$kind/fillers"
        ;;
      *)
        if [ -n "$kind" ] && [ -n "$part" ]; then
          printf '%s\n' "$line" >> "$root/$kind/$part.md"
        fi
        ;;
    esac
  done < "$ex"

  fail=0
  for kind in analysis questionnaire techspec delivery-note ticket-comment; do
    if [ ! -s "$root/$kind/after.md" ] || [ ! -s "$root/$kind/before.md" ]; then
      printf '%s\n' "fail example: missing before/after for $kind" >&2
      fail=1
      continue
    fi
    if ! check_file "$kind" "$root/$kind/before.md"; then
      fail=1
    fi
    if ! check_file "$kind" "$root/$kind/after.md"; then
      fail=1
    fi
    if [ ! -s "$root/$kind/facts" ] || [ ! -s "$root/$kind/fillers" ]; then
      printf '%s\n' "fail example: $kind needs a fact and a filler phrase" >&2
      fail=1
      continue
    fi
    while IFS= read -r item || [ -n "$item" ]; do
      [ -n "$item" ] || continue
      if ! grep -qF -- "$item" "$root/$kind/before.md" || ! grep -qF -- "$item" "$root/$kind/after.md"; then
        printf '%s\n' "fail example: $kind dropped a fact: $item" >&2
        fail=1
      fi
    done < "$root/$kind/facts"
    while IFS= read -r item || [ -n "$item" ]; do
      [ -n "$item" ] || continue
      if ! grep -qF -- "$item" "$root/$kind/before.md"; then
        printf '%s\n' "fail example: $kind filler missing from the before text: $item" >&2
        fail=1
      fi
      if grep -qF -- "$item" "$root/$kind/after.md"; then
        printf '%s\n' "fail example: $kind kept filler: $item" >&2
        fail=1
      fi
    done < "$root/$kind/fillers"
    first=$(sections_for "$kind" | head -n 1)
    dropped=$(mktemp)
    grep -vF -e "$first" -- "$root/$kind/after.md" > "$dropped" || true
    if check_file "$kind" "$dropped" >/dev/null 2>&1; then
      printf '%s\n' "fail example: $kind passed without $first" >&2
      fail=1
    fi
    rm -f "$dropped"
  done
  rm -rf "$root"
  trap - EXIT
  return "$fail"
}

if [ "$#" -ne 2 ] || [ ! -f "$2" ]; then
  printf '%s\n' "usage: scripts/check-draft-sections.sh <kind> <draft>" >&2
  printf '%s\n' "   or: scripts/check-draft-sections.sh --example <file>" >&2
  exit 2
fi

if [ "$1" = "--example" ]; then
  check_example "$2"
  exit $?
fi

status=0
check_file "$1" "$2" || status=$?
if [ "$status" -eq 0 ]; then
  printf '%s\n' "ok draft-sections: $1 $2"
fi
exit "$status"
