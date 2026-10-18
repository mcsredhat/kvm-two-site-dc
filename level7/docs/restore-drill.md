# Restore drill — web1

1. On kvm2: `sudo /usr/local/sbin/restore-test.sh web1`
2. It takes the newest online backup in /backup/web1, verifies its sha256, reads /root/marker offline (virt-cat),
   defines a copy "web1-restore" from the backed-up XML on the isolated network restore-net, boots it,
   waits for the guest agent, logs PASS/FAIL to /var/log/restore-test.log and a metric for Prometheus, then deletes the copy.
3. Result 18 Oct 2026: PASS, backup web1-2026-10-18-1503.qcow2, restore + boot 36 s.
4. Real restore (not a test): the same steps, but with the original name, the original disk path and br10.
   Shut down the broken web1 first. Never run two copies with the same MAC on br10.
