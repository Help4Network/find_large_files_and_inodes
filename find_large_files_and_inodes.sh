#!/bin/bash
# Help4 Network Property - Public License - Version 1.5.3 (unchanged terms)
VERSION="1.5.3-stable"
set -euo pipefail
export LC_ALL=C

# ---------- config ----------
TOP_FILES=20
INODE_THRESHOLD=10000           # flag dirs holding > this many files (immediate files, not recursive)
LARGE_FILE_BYTES=$((1<<30))     # 1 GiB
EXCLUDE_DIRS=(virtfs cloudlinux some_other_system_dir)
KNOWN_USER_PATTERN='^[a-zA-Z0-9][a-zA-Z0-9_-]*$'
PARALLEL=0                      # 0=sequential; 1=background per-user

# ---------- helpers ----------
is_excluded_dir() {
  local d=${1##*/}
  for e in "${EXCLUDE_DIRS[@]}"; do [ "$d" = "$e" ] && return 0; done
  return 1
}
hr() { numfmt --to=iec --suffix=B "$1"; }
rule() { echo "---- $* ----"; }

# dedupe /home roots by device+inode (if /home2 -> /home, keep only one)
get_home_roots() {
  local roots=()
  [ -d /home ]  && roots+=("/home")
  [ -e /home2 ] && roots+=("/home2")
  if [ "${#roots[@]}" -le 1 ]; then
    echo "${roots[@]}"; return
  fi
  local s1 s2
  s1=$(stat -Lc '%d:%i' "${roots[0]}" 2>/dev/null || echo x)
  s2=$(stat -Lc '%d:%i' "${roots[1]}" 2>/dev/null || echo y)
  if [ "$s1" = "$s2" ]; then
    echo "${roots[0]}"
  else
    echo "${roots[@]}"
  fi
}

say() { echo "$*"; }

# ---------- start ----------
say "Starting directory analysis (Version $VERSION)"
rule "Top-level usage of /"
du -x -h -d1 / 2>/dev/null | sort -hr | head -50
echo

# home roots
read -r -a HOME_ROOTS <<<"$(get_home_roots)"
[ "${#HOME_ROOTS[@]}" -eq 0 ] && HOME_ROOTS=("/home")

# per-home totals
for H in "${HOME_ROOTS[@]}"; do
  [ -d "$H" ] || continue
  sz=$(du -x -B1 -s "$H" 2>/dev/null | awk '{print $1}')
  echo "Total size of $H: $(hr "${sz:-0}")"
done
echo

# collect user dirs
USER_DIRS=()
for H in "${HOME_ROOTS[@]}"; do
  [ -d "$H" ] || continue
  while IFS= read -r -d '' u; do
    bn=${u##*/}
    is_excluded_dir "$bn" && continue
    [[ $bn =~ $KNOWN_USER_PATTERN ]] || continue
    USER_DIRS+=("$u")
  done < <(find "$H" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
done

largest_files_for_user() {
  local u="$1" bn="${1##*/}"
  rule "Top ${TOP_FILES} files for user: ${bn}"
  find "$u" -xdev -type f -printf '%s\t%p\n' 2>/dev/null \
    | sort -k1,1nr \
    | head -n "$TOP_FILES" \
    | numfmt --to=iec --suffix=B --field=1 --delimiter=$'\t'
  echo
}

inode_hotspots_for_user() {
  local u="$1"
  find "$u" -xdev -type f -printf '%h\n' 2>/dev/null \
    | sort | uniq -c \
    | awk -v T="$INODE_THRESHOLD" '$1>T {print "High inode usage: " $2 " - " $1 " files"}'
  echo
}

anomalies_in_home_root() {
  local H="$1"
  rule "Anomalous folders in $H"
  while IFS= read -r -d '' f; do
    base=${f##*/}
    is_excluded_dir "$base" && continue
    [[ $base =~ $KNOWN_USER_PATTERN ]] && continue
    du -sh "$f" 2>/dev/null | awk '{print "Erroneous folder: " $2 " (" $1 ")"}'
  done < <(find "$H" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
  echo
}

# anomalies per home root
for H in "${HOME_ROOTS[@]}"; do
  [ -d "$H" ] && anomalies_in_home_root "$H"
done

# per-user scans
rule "Per-user largest files and inode hotspots"
if [ "$PARALLEL" -eq 1 ]; then
  pids=()
  for u in "${USER_DIRS[@]}"; do
    ( largest_files_for_user "$u"; inode_hotspots_for_user "$u" ) & pids+=($!)
  done
  for p in "${pids[@]}"; do wait "$p"; done
else
  for u in "${USER_DIRS[@]}"; do
    largest_files_for_user "$u"
    inode_hotspots_for_user "$u"
  done
fi

# build prune array for system-wide scans
PRUNE=( -path /proc -prune -o -path /sys -prune -o -path /dev -prune -o )
for H in "${HOME_ROOTS[@]}"; do PRUNE+=( -path "$H" -prune -o ); done
for e in "${EXCLUDE_DIRS[@]}"; do PRUNE+=( -path "*/$e/*" -prune -o ); done

rule "Large files (>= $(hr $LARGE_FILE_BYTES)) outside /home*"
/usr/bin/find / "${PRUNE[@]}" -type f -size +"${LARGE_FILE_BYTES}c" -printf '%s\t%p\n' 2>/dev/null \
  | sort -k1,1nr \
  | numfmt --to=iec --suffix=B --field=1 --delimiter=$'\t' \
  | head -200
echo

rule "Inode hotspots (immediate dir > ${INODE_THRESHOLD} files) outside /home*"
/usr/bin/find / "${PRUNE[@]}" -type f -printf '%h\n' 2>/dev/null \
  | sort | uniq -c \
  | awk -v T="$INODE_THRESHOLD" '$1>T {printf "%7d\t%s\n",$1,$2}'
echo

# deleted-but-open files (space leaks)
if command -v lsof >/dev/null 2>&1; then
  rule "Deleted-but-open files (space leaks)"
  lsof +L1 -nP 2>/dev/null | awk '$7 ~ /^[0-9]+$/ {print $7 "\t" $9}' \
    | sort -nr \
    | numfmt --to=iec --suffix=B --field=1 --delimiter=$'\t' \
    | head -50
  echo
fi

echo "Directory analysis complete."
echo "Script provided by Help4 Network. Public credit required for commercial use."
