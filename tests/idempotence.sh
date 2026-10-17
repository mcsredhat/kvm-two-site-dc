#!/usr/bin/env bash
# Idempotence proof: check-run clean, then two real runs, the second must change nothing.
# Full Ansible output goes to tests/last-run.log ; the screen shows progress, recaps, verdict.
set -euo pipefail
cd "$(dirname "$0")/.."
LOG=tests/last-run.log ; : > "$LOG"

# password asked on the terminal itself -> visible even if stdout/stderr are redirected
PWFILE=$(mktemp) ; chmod 600 "$PWFILE" ; trap 'rm -f "$PWFILE"' EXIT
read -rsp "VAULT password: " PW </dev/tty ; echo >/dev/tty
printf '%s\n' "$PW" > "$PWFILE" ; unset PW

fail=0
run() {   # $1 = label, $2 = must-be-zero|any, rest = extra ansible args
  local label=$1 rule=$2 ; shift 2
  local start=$SECONDS
  echo "=== $label ... (running, full output in $LOG)"
  echo "=== $label" >> "$LOG"
  if ! ansible-playbook site.yml --vault-password-file "$PWFILE" "$@" >> "$LOG" 2>&1; then
      tail -n 5 "$LOG" | sed "s/^/   /"
      echo "   ansible-playbook returned an error"; fail=1
  fi
  local recap ; recap=$(sed -n '/PLAY RECAP/,$p' "$LOG" | tail -n 3)
  echo "$recap" | grep -E '^(kvm|[a-z0-9])' | sed 's/^/   /' || true
  echo "   ($((SECONDS-start)) s)"
  if grep -Eq 'failed=[1-9]|unreachable=[1-9]' <<<"$recap"; then echo "   FAIL: failures"; fail=1; fi
  if [ "$rule" = must-be-zero ] && grep -Eq 'changed=[1-9]' <<<"$recap"; then
      echo "   FAIL: something changed (drift or not idempotent)"; fail=1
  fi
}

run "dry run (drift check)" must-be-zero --check
run "run 1 (apply)"         any
run "run 2 (idempotence)"   must-be-zero

echo
if [ "$fail" -eq 0 ]; then echo "IDEMPOTENCE: PASS (no drift, run 2 changed=0 on all hosts)"
else echo "IDEMPOTENCE: FAIL  -> read $LOG (grep -n -B2 -A8 'changed:\|fatal:' $LOG)"; exit 1; fi
