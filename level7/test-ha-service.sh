#!/bin/bash
# test-ha-service.sh : Level 7 mini-project acceptance tests. Run on kvm1.
cd "$(dirname "$0")" || exit 1
source ./l7env.sh
PASS=0 ; FAIL=0
check() { local d=$1; shift
  if "$@" >/dev/null 2>&1; then printf '  [PASS] %s\n' "$d"; PASS=$((PASS+1))
  else printf '  [FAIL] %s\n' "$d"; FAIL=$((FAIL+1)); fi; }
export -f v2 where_web1 vm_ssh ip_of 2>/dev/null
export K1 K2 WEB1 SSHOPT

echo "== Mini-project acceptance =="
check "service answers"               bash -c "vm_ssh v10a 'curl -sf -m 3 http://$WEB1:8080/' | grep -q alive"
check "web1 lives at home (kvm2)"     bash -c '[ "$(where_web1)" = kvm2 ]'
check "web1 autostart on kvm2"        bash -c 'v2 dominfo web1 | grep -Eq "Autostart: +enable"'
check "backup timer active on kvm2"   bash -c 'ssh kvm2 systemctl is-active backup-web1.timer | grep -q ^active'
check "restore timer active on kvm2"  bash -c 'ssh kvm2 systemctl is-active restore-test-web1.timer | grep -q ^active'
check "last restore test PASS"        bash -c "curl -s -m 5 http://$K2:9100/metrics | grep -Eq '^kvm_restore_test_success\{vm=\"web1\"\} 1'"
check "no backup or restore alert"    bash -c "! curl -s -m 5 http://$K2:9090/api/v1/alerts | grep -Eq '\"alertname\":\"(BackupTooOld|RestoreTestFailed)\"'"
check "SLO stated in README (4 met)"  bash -c '[ "$(grep -c "| yes |" README.md)" -ge 4 ]'
check "report has 3 drills"           bash -c '[ "$(grep -c "^## Drill" docs/drill-report.md)" -ge 3 ]'
check "cluster resource started"      bash -c 'ssh cl1 sudo pcs resource status ha-web | grep -q Started'
echo ; echo "== $PASS passed, $FAIL failed ==" ; [ "$FAIL" -eq 0 ]
