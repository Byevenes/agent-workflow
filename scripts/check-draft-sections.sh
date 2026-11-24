#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

usage() {
  printf '%s\n' "usage: scripts/check-draft-sections.sh <kind> <draft>" >&2
  printf '%s\n' "   or: scripts/check-draft-sections.sh --example <file>" >&2
  printf '%s\n' "   or: scripts/check-draft-sections.sh questionnaire <draft> [--analysis <file>] [--max-per-owner N]" >&2
}

sections_for() {
  case $1 in
    analysis)
      printf '%s\n' '## Resumen' '## Hallazgos' '## Incertidumbres' '## Fuentes'
      ;;
    questionnaire)
      printf '%s\n' '## Preguntas' '## Prioridad' '## Bloqueantes'
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
      printf '%s\n' '## Requerimiento' '## Evidencia' '## Abierto'
      ;;
    qa-inputs)
      printf '%s\n' \
        '## Funcionalidades modificadas' \
        '## Dónde se gatillan' \
        '## Referencia al código' \
        '## Fuera de alcance' \
        '## Casos de QA sugeridos'
      ;;
    *)
      usage
      return 2
      ;;
  esac
}

is_uint() {
  case $1 in
    ''|*[!0-9]*) return 1 ;;
  esac
}

is_question() {
  n=${1#Q}
  n=${n%%.*}
  case $n in
    ''|*[!0-9]*) return 1 ;;
  esac
  case $1 in
    "Q${n}. "*) return 0 ;;
    *) return 1 ;;
  esac
}

question_owner() {
  t=$1
  case $t in
    *' dueño:'*) ;;
    *) return 0 ;;
  esac
  prefix=${t%' dueño:'*}
  role=${t#"$prefix dueño:"}
  case $role in
    ''|*[!A-Za-z]*) return 0 ;;
  esac
  printf '%s' "$role"
}

question_body() {
  t=$1
  n=${t#Q}
  n=${n%%.*}
  t=${t#"Q${n}. "}
  role=$(question_owner "$1")
  if [ -n "$role" ]; then
    t=${t%" dueño:$role"}
  fi
  printf '%s' "$t"
}

norm_text() {
  t=$(printf '%s' "$1" | tr -s '[:space:]' ' ')
  t=${t# }
  t=${t% }
  t=$(printf '%s' "$t" | tr '[:upper:]' '[:lower:]')
  while :; do
    case $t in
      ¿*) t=${t#¿} ;;
      *) break ;;
    esac
  done
  while :; do
    case $t in
      *.) t=${t%.} ;;
      *\?) t=${t%\?} ;;
      *) break ;;
    esac
  done
  printf '%s' "$t"
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
    if ! grep -qxF -- "$heading" "$file"; then
      printf '%s\n' "fail $kind: missing $heading" >&2
      missing=1
    fi
  done <<EOF
$headings
EOF
  if [ "$kind" = questionnaire ]; then
    check_questionnaire "$file" || missing=1
  fi
  return "$missing"
}

check_questionnaire() {
  file=$1
  badq=0
  qdir=$(mktemp -d)
  seen=$qdir/seen
  counts=$qdir/counts
  premises=$qdir/premises
  : > "$seen"
  : > "$counts"
  : > "$premises"
  if [ -n "$analysis" ]; then
    awk '
      $0 == "## Supuestos" { p = 1; next }
      /^## / { p = 0 }
      p { print }
    ' "$analysis" | while IFS= read -r pline || [ -n "$pline" ]; do
      printf '%s\n' "$(norm_text "$pline")"
    done > "$premises"
  fi
  while IFS= read -r line || [ -n "$line" ]; do
    case $line in
      '## Ronda actual')
        ;;
      '## '*)
        if ! printf '%s\n' "$headings" | grep -qxF -- "$line"; then
          printf '%s\n' "fail questionnaire: extra heading $line; put the owner at line end as dueño:<rol>" >&2
          badq=1
        fi
        ;;
    esac
    if is_question "$line"; then
      n=${line#Q}
      n=${n%%.*}
      role=$(question_owner "$line")
      if [ -z "$role" ]; then
        printf '%s\n' "fail questionnaire: Q${n} has no dueño; add dueño:<rol> at line end" >&2
        badq=1
      else
        printf '%s\n' "$role" >> "$counts"
      fi
      key=$(norm_text "$(question_body "$line")")
      if grep -qxF -- "$key" "$seen"; then
        printf '%s\n' "fail questionnaire: Q${n} duplicates an earlier question; drop the copy" >&2
        badq=1
      else
        printf '%s\n' "$key" >> "$seen"
      fi
      if grep -qxF -- "$key" "$premises"; then
        printf '%s\n' "fail questionnaire: Q${n} repeats a supuesto" >&2
        badq=1
      fi
    fi
  done < "$file"
  frontier=0
  if grep -qxF -- '## Ronda actual' "$file"; then
    frontier=1
  fi
  check_frontier "$file" "$frontier" || badq=1
  if [ "$frontier" -eq 0 ] && [ "$(awk -v m="$max" 'BEGIN { print (m + 0 == 0) }')" -eq 0 ]; then
    if ! awk -v max="$max" '
      NF { c[$0]++ }
      END {
        bad = 0
        for (r in c) {
          if (c[r] + 0 > max + 0) {
            printf "fail questionnaire: dueño:%s has %d questions, max %d (set ZSTACK_MAX_QUESTIONS_PER_OWNER)\n", r, c[r], max + 0
            bad = 1
          }
        }
        exit bad
      }
    ' "$counts" >&2; then
      badq=1
    fi
  fi
  rm -rf "$qdir"
  return "$badq"
}

check_frontier() {
  awk -v max="$max" -v frontier="$2" '
    function fail(msg) { printf "fail questionnaire: %s\n", msg; bad = 1 }
    function ready(id,   n, i, ds) {
      if (est[id] != "pendiente") return 0
      if (dep[id] == "-") return 1
      n = split(dep[id], ds, ",")
      for (i = 1; i <= n; i++) if (est[ds[i]] != "respondida") return 0
      return 1
    }
    BEGIN { bad = 0; nq = 0; nr = 0; last = ""; sec = "" }
    /^## / { sec = $0; last = ""; next }
    /^Q[0-9]+\. / {
      id = $0
      sub(/\. .*/, "", id)
      if (!(id in q)) order[++nq] = id
      q[id] = 1
      o = $0
      if (o ~ / dueño:[A-Za-z]+$/) { sub(/.* dueño:/, "", o); owner[id] = o }
      last = id
      next
    }
    /^[ \t]+estado:/ {
      if (last == "") { fail("estado line without a question above; put it right under its Qn line"); next }
      m = $0
      sub(/^[ \t]+/, "", m)
      if (m !~ /^estado:[a-z]+ bloqueante:(sí|no) depende de:(-|Q[0-9]+(,Q[0-9]+)*)$/) {
        fail(last " estado line must read: estado:<pendiente|respondida|obsoleta> bloqueante:<sí|no> depende de:<Qn,Qm|->")
        last = ""
        next
      }
      split(m, parts, " ")
      st = substr(parts[1], 8)
      if (st != "pendiente" && st != "respondida" && st != "obsoleta") {
        fail(last " has estado:" st "; use pendiente, respondida or obsoleta")
      }
      meta[last] = 1
      est[last] = st
      blk[last] = substr(parts[2], 12)
      dep[last] = substr(parts[4], 4)
      last = ""
      next
    }
    sec == "## Ronda actual" && NF {
      if ($0 ~ /^- Q[0-9]+$/) {
        r = substr($0, 3)
        if (r in inr) fail("## Ronda actual lists " r " twice")
        else { inr[r] = 1; ronda[++nr] = r }
      } else {
        fail("## Ronda actual takes one \"- Qn\" per line")
      }
      last = ""
      next
    }
    { last = "" }
    END {
      for (i = 1; i <= nq; i++) {
        id = order[i]
        if (!(id in meta)) {
          if (frontier) fail(id " has no estado line; add estado:<...> bloqueante:<sí|no> depende de:<Qn|-> under it")
          continue
        }
        if (dep[id] == "-") continue
        n = split(dep[id], ds, ",")
        for (j = 1; j <= n; j++) {
          if (ds[j] == id) fail(id " depends on itself")
          else if (!(ds[j] in q)) fail(id " depends on " ds[j] ", which is not a question")
        }
      }
      if (!frontier) exit bad
      open = 0; nready = 0; block = 0
      for (i = 1; i <= nq; i++) {
        id = order[i]
        if (!(id in meta)) continue
        if (est[id] == "pendiente") {
          open++
          if (id in owner) per[owner[id]]++
        }
        if (ready(id)) { nready++; if (blk[id] == "sí") block++ }
      }
      for (i = 1; i <= nr; i++) {
        r = ronda[i]
        if (!(r in q)) { fail("## Ronda actual lists " r ", which is not a question"); continue }
        if (!(r in meta)) continue
        if (est[r] != "pendiente") { fail(r " in ## Ronda actual is " est[r] "; only pendiente questions go out"); continue }
        if (!ready(r)) {
          n = split(dep[r], ds, ",")
          for (j = 1; j <= n; j++) {
            d = ds[j]
            if ((d in q) && est[d] != "respondida") {
              s = (d in est) ? est[d] : "sin estado"
              fail(r " in ## Ronda actual depends on " d " (" s "); ask " d " first and hold " r " for a later round")
            }
          }
          continue
        }
        if (block > 0 && blk[r] == "no") fail(r " in ## Ronda actual is not bloqueante while bloqueante questions are open; hold it for a later round")
      }
      for (i = 1; i <= nq; i++) {
        id = order[i]
        if ((id in meta) && ready(id) && blk[id] == "sí" && !(id in inr)) fail(id " is on the frontier (bloqueante, dependencies respondida) but missing from ## Ronda actual")
      }
      if (open > 0 && nready == 0) fail("no pendiente question is ready; check depende de for a cycle or a dependency marked obsoleta")
      if (nready > 0 && nr == 0) fail("## Ronda actual is empty; list the frontier")
      if (max + 0 > 0) {
        for (o in per) {
          if (per[o] > max + 0) {
            printf "fail questionnaire: dueño:%s has %d pendiente questions, max %d (set ZSTACK_MAX_QUESTIONS_PER_OWNER)\n", o, per[o], max + 0
            bad = 1
          }
        }
      }
      exit bad
    }
  ' "$1" >&2
}

known_kind() {
  case $1 in
    analysis|questionnaire|techspec|delivery-note|ticket-comment|qa-inputs) return 0 ;;
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

analysis=
max=15

if [ "$#" -lt 2 ]; then
  usage
  exit 2
fi

if [ "$1" = "--example" ]; then
  if [ "$#" -ne 2 ] || [ ! -f "$2" ]; then
    usage
    exit 2
  fi
  check_example "$2"
  exit $?
fi

kind=$1
file=$2
shift 2
have_analysis=0
have_max=0
max_flag=
while [ "$#" -gt 0 ]; do
  case $1 in
    --analysis)
      if [ "$#" -lt 2 ]; then
        usage
        exit 2
      fi
      analysis=$2
      have_analysis=1
      shift 2
      ;;
    --max-per-owner)
      if [ "$#" -lt 2 ]; then
        usage
        exit 2
      fi
      max_flag=$2
      have_max=1
      shift 2
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if [ "$have_analysis" -eq 1 ] || [ "$have_max" -eq 1 ]; then
  if [ "$kind" != questionnaire ]; then
    usage
    exit 2
  fi
fi

if [ ! -f "$file" ]; then
  usage
  exit 2
fi

if [ "$kind" = questionnaire ]; then
  if [ -n "${ZSTACK_MAX_QUESTIONS_PER_OWNER:-}" ]; then
    max=$ZSTACK_MAX_QUESTIONS_PER_OWNER
    if ! is_uint "$max"; then
      printf '%s\n' "fail: ZSTACK_MAX_QUESTIONS_PER_OWNER must be a non-negative integer" >&2
      exit 2
    fi
  elif [ "$have_max" -eq 1 ]; then
    max=$max_flag
    if ! is_uint "$max"; then
      printf '%s\n' "fail: --max-per-owner must be a non-negative integer" >&2
      exit 2
    fi
  fi
  if [ "$have_analysis" -eq 1 ] && [ ! -f "$analysis" ]; then
    printf '%s\n' "fail: not a file: $analysis" >&2
    exit 1
  fi
fi

status=0
check_file "$kind" "$file" || status=$?
if [ "$status" -eq 0 ]; then
  printf '%s\n' "ok draft-sections: $kind $file"
fi
exit "$status"
