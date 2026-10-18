# l7env.sh : source on kvm1.  Shell FUNCTIONS: never put sudo in front of them.
source ~/kvm-course/level6/net.env          # K1, K2, ME
source ~/kvm-course/level6/helpers.sh       # ip_of, vm_ssh, vm_wait, SSHOPT (LIBVIRT_DEFAULT_URI=qemu:///system)
export WEB1=192.168.10.50
v2()         { virsh -c qemu+ssh://kvm2/system "$@"; }                      # virsh on kvm2, from kvm1
where_web1() { if virsh domstate web1 2>/dev/null | grep -q running; then echo kvm1
               elif v2 domstate web1 2>/dev/null | grep -q running; then echo kvm2; else echo none; fi; }
web1_ssh()   { ssh $SSHOPT -J "devops@$(ip_of v10a)" "devops@$WEB1" "$@"; }  # through v10a, over br10
