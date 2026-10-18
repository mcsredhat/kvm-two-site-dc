#!/bin/bash
# validate-level7.sh : Level 7 checks (two sites over Tailscale + nested cluster on kvm1). Run on kvm1.
cd "$(dirname "$0")" || exit 1
source ./l7env.sh                                    # K1, K2, v2, where_web1, vm_ssh, WEB1
PASS=0 ; FAIL=0
check() {  # check "description" command...
  local desc=$1 ; shift
  if "$@" >/dev/null 2>&1; then printf '  [PASS] %s\n' "$desc"; PASS=$((PASS+1))
  else printf '  [FAIL] %s\n' "$desc"; FAIL=$((FAIL+1)); fi
}
web1_xml() { virsh dumpxml web1 2>/dev/null || v2 dumpxml web1; }
# bash -c starts a new shell: export the helpers and variables so the checks can use them
export -f v2 where_web1 vm_ssh ip_of web1_xml 2>/dev/null
export K1 K2 WEB1 SSHOPT

echo "== Level 7 validation =="
echo "-- Part A: migration"
check "kvm2 answers over Tailscale"            tailscale ping -c 1 --timeout 5s kvm2
check "libvirt on kvm2 via qemu+ssh"           v2 list
check "nfspool running on kvm1 and kvm2"       bash -c 'virsh pool-info nfspool | grep -q running && v2 pool-info nfspool | grep -q running'
check "web1 is running (at home: kvm2)"        bash -c '[ "$(where_web1)" = kvm2 ]'
check "web1 uses a custom baseline CPU"        bash -c "web1_xml | grep -q \"cpu mode='custom'\""
check "web1 NIC on br10 with MTU 1230"         bash -c "web1_xml | grep -A10 \"<interface type='bridge'>\" | grep -q \"mtu size='1230'\""
check "web1 service answers from v10a"         bash -c "vm_ssh v10a 'curl -sf -m 3 http://$WEB1:8080/' | grep -q alive"
check "Drill 1 (migration) has numbers"        bash -c 'grep -A6 "Drill 1" docs/drill-report.md | grep -Eq "kvm[12] → kvm[12] \| *[0-9]"'

echo "-- Part B: backup and restore"
check "backup fresher than 26 h (metric)"      bash -c "curl -s -m 5 http://$K2:9100/metrics | awk '/^kvm_backup_last_success_timestamp_seconds/ {f=1; ok=(systime()-\$2 < 93600)} END {exit !(f && ok)}'"
check "last restore test passed (metric)"      bash -c "curl -s -m 5 http://$K2:9100/metrics | grep -Eq '^kvm_restore_test_success\{vm=\"web1\"\} 1'"
check "restore drill documented"               test -s docs/restore-drill.md

echo "-- Part C: high availability (nested on kvm1)"
check "cluster nodes online"                   bash -c "ssh cl1 sudo pcs status | grep -Eq 'Online: \[ cl1 cl2 \]'"
check "cluster quorate"                        bash -c "ssh cl1 sudo pcs quorum status | grep -Eq 'Quorate: +Yes'"
check "stonith enabled and device started"     bash -c "ssh cl1 sudo pcs property config stonith-enabled | grep -q true && ssh cl1 sudo pcs stonith status | grep -q Started"
check "ha-web resource started"                bash -c "ssh cl1 sudo pcs resource status ha-web | grep -q Started"
check "no failed resource actions"             bash -c "! ssh cl1 sudo pcs status | grep -q 'Failed Resource Actions'"
check "a successful fence is recorded"         bash -c "ssh cl1 sudo pcs stonith history | grep -q successful"
check "Drill 2 (RTO) has a number"             bash -c 'grep -A4 "Drill 2" docs/drill-report.md | grep -Eq "\| *[0-9]+ *\|"'
check "kvm1: no masquerade on libvirt zone"    bash -c "sudo firewall-cmd --zone=libvirt --query-masquerade | grep -q no"

echo "-- Part D: monitoring"
check "Prometheus ready on kvm2"               bash -c "curl -s -m 5 http://$K2:9090/-/ready | grep -qi ready"
check "both hosts scraped (sum(up) == 2)"      bash -c "[ \"\$(curl -s -m 5 'http://$K2:9090/api/v1/query?query=sum(up)' | python3 -c 'import json,sys; print(int(float(json.load(sys.stdin)[\"data\"][\"result\"][0][\"value\"][1])))')\" = 2 ]"
check "7 alert rules loaded and healthy"       bash -c "[ \"\$(curl -s -m 5 http://$K2:9090/api/v1/rules | python3 -c 'import json,sys; print(sum(r[\"health\"]==\"ok\" for g in json.load(sys.stdin)[\"data\"][\"groups\"] for r in g[\"rules\"]))')\" = 7 ]"
check "no alert firing now"                    bash -c "! curl -s -m 5 http://$K2:9090/api/v1/alerts | grep -q '\"state\":\"firing\"'"
check "node_exporter only on Tailscale (kvm1)" bash -c "ss -ltn | grep -q \"$K1:9100\""

echo
echo "== $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
