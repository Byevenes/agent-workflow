#!/bin/sh
set -eu
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_COMMON_DIR GIT_PREFIX

pin_repo=https://github.com/addyosmani/agent-skills
pin_tag=0.6.17
pin_sha=8c99fa36d90068c82d547f7c12a9d67a3e95f4ee

repo=${SECURITY_UPSTREAM_REPO:-$pin_repo}
tag=${SECURITY_UPSTREAM_TAG:-$pin_tag}
sha=${SECURITY_UPSTREAM_SHA:-$pin_sha}
HOME_DIR=${HOME:?}
name=security-and-hardening
dest=$HOME_DIR/.agents/skills/$name
keep_root=$HOME_DIR/.cache/agent-workflow/replaced-skills

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT INT TERM

git clone -q --depth 1 --branch "$tag" "$repo" "$work/src" 2>/dev/null || { echo "install-security-hardening: clone of $repo at $tag failed" >&2; exit 1; }
got=$(git -C "$work/src" rev-parse HEAD)
if [ "$got" != "$sha" ]; then
  echo "install-security-hardening: $tag is $got, pin is $sha" >&2
  exit 1
fi
[ -f "$work/src/skills/$name/SKILL.md" ] || { echo "install-security-hardening: skills/$name/SKILL.md missing upstream" >&2; exit 1; }
[ -f "$work/src/references/security-checklist.md" ] || { echo "install-security-hardening: references/security-checklist.md missing upstream" >&2; exit 1; }

stage=$work/$name
cp -R "$work/src/skills/$name" "$stage"
mkdir -p "$stage/references"
cp "$work/src/references/security-checklist.md" "$stage/references/security-checklist.md"
sed 's#\.\./\.\./references/security-checklist\.md#references/security-checklist.md#g' "$stage/SKILL.md" > "$work/SKILL.md"
mv "$work/SKILL.md" "$stage/SKILL.md"
if grep -q '\.\./\.\./references/' "$stage/SKILL.md"; then
  echo "install-security-hardening: SKILL.md still points outside the skill folder" >&2
  exit 1
fi
grep -o 'references/[A-Za-z0-9._-]*\.md' "$stage/SKILL.md" | sort -u > "$work/refs"
while IFS= read -r ref; do
  [ -f "$stage/$ref" ] || { echo "install-security-hardening: broken link $ref" >&2; exit 1; }
done < "$work/refs"
printf 'repo %s\ntag %s\nsha %s\n' "$repo" "$tag" "$sha" > "$stage/.upstream"

stamp=$(date +%Y%m%d%H%M%S)-$$
move_aside() {
  ma_path=$1
  ma_tag=$2
  mkdir -p "$keep_root"
  mv "$ma_path" "$keep_root/$name-$stamp-$ma_tag"
  echo "moved $ma_path to $keep_root/$name-$stamp-$ma_tag"
}

mkdir -p "$(dirname "$dest")"
if [ -f "$dest/.upstream" ] && cmp -s "$dest/.upstream" "$stage/.upstream" && diff -r "$dest" "$stage" >/dev/null 2>&1; then
  echo "ok $dest already at $tag ($sha)"
elif [ -L "$dest" ]; then
  rm "$dest"
elif [ -e "$dest" ]; then
  move_aside "$dest" agents
fi
if [ ! -e "$dest" ]; then
  mv "$stage" "$dest"
  echo "install $dest ($tag, $sha)"
fi

for link in "$HOME_DIR/.cursor/skills/$name" "$HOME_DIR/.config/opencode/skills/$name"; do
  if [ -e "$link" ] && [ ! -L "$link" ]; then
    move_aside "$link" "$(basename "$(dirname "$(dirname "$link")")")"
  fi
  mkdir -p "$(dirname "$link")"
  ln -sfn "$dest" "$link"
  echo "link $link"
done
