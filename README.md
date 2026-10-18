# Two-site KVM datacenter as code (Level 6)

Two RHEL 9 laptops at two sites (work: phone hotspot, home: Wi-Fi), joined only by **Tailscale**,
run one virtual datacenter: two stretched L2 segments (**VXLAN** VNI 10 / 20), shared storage
(**NFS** pool, **iSCSI** LUN), all managed by **Ansible** — drift detected, repaired, rebuilt from zero.
## Roles
| Role | Manages | Notes |
|---|---|---|
| `base` | packages, no sleep/lid, chrony, tuned `virtual-host` | tuned drift is visible in `--check` |
| `firewall` | `tailscale0 br10 br20` in `trusted`; storage services closed on Wi-Fi | close, then assert (policy as code) |
| `vxlan` | `/etc/vxlan-lab.conf` (peer computed from inventory), script, unit, boot-order drop-ins | live drift: read → report → repair → assert; re-plugs VM ports |
| `storage` | NFS export + `nfspool` (both), iSCSI target (kvm2), initiator + `iscsipool` (kvm1) | read-then-act on `targetcli` / `iscsiadm` |

## Run
```bash
ansible-galaxy collection install -r collections/requirements.yml
ansible-playbook site.yml --ask-vault-pass --check --diff   # drift report, changes nothing
ansible-playbook site.yml --ask-vault-pass                  # apply / repair
./tests/idempotence.sh                                      # dry run clean + 2 runs, 2nd must be changed=0
~/kvm-course/level6/dc-validate.sh                          # traffic matrix from the VMs
```
Per-host sudo passwords live in `host_vars/<host>/vault.yml` (Ansible Vault, AES256).

## What was proven
- **Idempotence:** dry run, run 1 and run 2 all `changed=0` (~60 s per run over a hotspot).
- **Fault drill:** 7 faults (firewall zone, NFS exposed on Wi-Fi, VXLAN MTU, deleted VXLAN, stopped pool,
  tuned profile, edited config) → all reported by `--check`, all repaired by one run.
- **Rebuild from zero:** VXLAN layer torn down and pools undefined on both hosts → one run → matrix `failures: 0`.
- **Lint:** `ansible-lint` clean (CI on every push).

## Lessons
See [docs/findings.md](docs/findings.md): every error met while building this, its cause and its fix.

Author: FARAJ — RHCSA/RHCE, Linux sysadmin → DevOps. Part of a KVM course (Levels 1–8) on RHEL 9.

Part of the KVM course: https://github.com/mcsredhat/kvm-course (Levels 1–7).
