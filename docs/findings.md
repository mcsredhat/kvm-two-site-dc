# Findings — building the Level 6 DC as code

| # | Symptom | Cause | Fix |
|---|---|---|---|
| 1 | `grep '"ansible_distribution"'` on setup output finds nothing | `callback_result_format = yaml`: output is YAML, not JSON | grep `'^ *ansible_distribution(_version)?:'` |
| 2 | `--check`: `list object has no element 0` in an assert | read-only `command` skipped in check mode → empty result | `check_mode: false` on read-only commands |
| 3 | `--diff` on kvm2: drop-in lacks `iscsi.service` | manual fix applied on kvm1 only (drift) | config captured from kvm1, applied to both |
| 4 | template adds an empty line | blank line before `EOF` in the `.j2`; Ansible keeps the final newline | no trailing blank line in templates |
| 5 | `/var/lib/iscsi_disks` 0755 → 0700 | code and reality disagree | decided 0700 (raw disk data, root only) |
| 6 | `-K` → `Sorry, try again` on one host | different sudo passwords per host | per-host `ansible_become_password` in Ansible Vault |
| 7 | `-J: unrecognized argument` | short flag absent in ansible-core 2.15 | `--ask-vault-pass` |
| 8 | test script "frozen" | `read -p` prompt goes to stderr, hidden by `2>/dev/null` | read secrets from `/dev/tty` |
| 9 | script exits silently | `set -euo pipefail` + `grep` with no match | `|| true` where empty is valid; print the log tail on error |
| 10 | 27 lint findings | role var prefix, task name casing, `no-changed-when`, unset modes | prefixed vars, `changed_when: true`, modes; reasoned `noqa` on the NFS mount point |
| 11 | handler design | `restart vxlan-lab` runs `ExecStop` = deletes bridges, cuts VMs | handler runs `vxlan-lab.sh up` (creates only what is missing) |
| 12 | deleted `vxlan20` / wrong MTU not repaired | files unchanged → handler never fires | read live state → report → repair → re-read → assert |
| 13 | matrix fails after rebuilding bridges | taps survive bridge deletion, unplugged | `vxlan-replug.sh` (dry-run aware) |
| 14 | dry run stops: assert fails | fix task not applied in `--check`, assert sees the fault | assert `when: not ansible_check_mode` |
| 15 | tuned drift missing from dry run | `command` tasks are skipped in `--check` | in check mode run `true` → reports changed, changes nothing |
| 16 | matrix passes with `vxlan20` deleted | VNI 20 has one VM: no "allow" test possible | live-state checks in the role cover it; traffic tests and state checks are complementary |
| 17 | `replugged` lines not shown | registered output hidden without `-v` | `debug` task when changed |
| 18 | hand `chmod` on a managed host | drift habit | change the code, let the run apply it |

**Known limits:** iSCSI `targetcli`/`iscsiadm` fixes are commands (not reported in `--check`, repaired on a real run);
NFS is `no_root_squash` limited to two tailnet IPs; ~60 s per run over a hotspot (SSH pipelining helps).
