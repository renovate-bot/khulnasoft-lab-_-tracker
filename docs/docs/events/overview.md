# Events

This section documents all of the different events that Tracker exposes.

## Everything is an event

Tracker uses eBPF technology to tap into your system and give you access to hundreds of events that help you understand how your system behaves. The events can be specified either through CLI with [filters] or with [policies].

eg:

Tracing `execve` events with [filters]:

```console
tracker --events execve
```

Tracing `execve` events with [policies]:

```
cat <<EOF >sample_policy.yaml
apiVersion: khulnasoft-labs.github.io/v1beta1
kind: TrackerPolicy
metadata:
	name: sample-policy
	annotations:
		description: traces execve events
spec:
	scope:
	  - global
	rules:
	  - event: execve
EOF
```

```
tracker --policies sample_policy.yaml
```

If no event is passed with [filters] or [policies], tracker will start with a sane default.
Below a list of tracker default events.

### Default events

Name   | Sets                              |
-------|-----------------------------------|
stdio_over_socket | [signatures default] |
k8s_api_connection |[signatures default] |
aslr_inspection | [signatures default] |
proc_mem_code_injection | [signatures default] |
docker_abuse | [signatures default] |
scheduled_task_mod | [signatures default] |
ld_preload | [signatures default] |
cgroup_notify_on_release | [signatures default] |
default_loader_mod | [signatures default] |
sudoers_modification | [signatures default] |
sched_debug_recon | [signatures default] |
system_request_key_mod | [signatures default] |
cgroup_release_agent | [signatures default] |
rcd_modification | [signatures default] |
core_pattern_modification | [signatures default] |
proc_kcore_read | [signatures default] |
proc_mem_access | [signatures default] |
hidden_file_created | [signatures default] |
anti_debugging | [signatures default] |
ptrace_code_injection | [signatures default] |
process_vm_write_inject | [signatures default] |
disk_mount | [signatures default] |
dynamic_code_loading | [signatures default] |
fileless_execution | [signatures default] |
illegitimate_shell  | [signatures default] |
kernel_module_loading | [signatures default] |
k8s_cert_theft | [signatures default] |
proc_fops_hooking | [signatures default] |
syscall_hooking | [signatures default] |
dropped_executable | [signatures default] |
creat | [default syscalls fs fs_file_ops] |
chmod | [default syscalls fs fs_file_attr] |
fchmod | [default syscalls fs fs_file_attr] |
chown | [default syscalls fs fs_file_attr] |
fchown | [default syscalls fs fs_file_attr] |
lchown | [default syscalls fs fs_file_attr]|
ptrace | [default syscalls proc] |
setuid | [default syscalls proc proc_ids] |
setgid | [default syscalls proc proc_ids] |
setpgid | [default syscalls proc proc_ids] |
setsid | [default syscalls proc proc_ids] |
setreuid | [default syscalls proc proc_ids] |
setregid | [default syscalls proc proc_ids] |
setresuid | [default syscalls proc proc_ids] |
setresgid | [default syscalls proc proc_ids] |
setfsuid | [default syscalls proc proc_ids] |
setfsgid | [default syscalls proc proc_ids] |
init_module | [default syscalls system system_module] | 
fchownat | [default syscalls fs fs_file_attr] |
fchmodat | [default syscalls fs fs_file_attr] |
setns | [default syscalls proc] |
process_vm_readv | [default syscalls proc] |
process_vm_writev | [default syscalls proc] |
finit_module | [default syscalls system system_module] |
memfd_create | [default syscalls fs fs_file_ops] |
move_mount | [default syscalls fs] |
sched_process_exec | [default proc] |
security_inode_unlink | [default lsm_hooks fs fs_file_ops] |
security_socket_connect | [default lsm_hooks net net_sock] |
security_socket_accept | [default lsm_hooks net net_sock] |
security_socket_bind | [default lsm_hooks net net_sock] |
security_sb_mount | [default lsm_hooks fs] |
container_create | [default containers] |
container_remove | [default containers] |
net_packet_icmp | [default network_events] |
net_packet_icmpv6 | [default network_events] |
net_packet_dns_request | [default network_events] |
net_packet_dns_response | [default network_events] |
net_packet_http_request | [default network_events] |
net_packet_http_response | [default network_events] |

### Sets

Events can be part of a set, for example on the table above we can see a few sets like `default`, `network_events`, `syscalls`. 
We can ask tracker to trace a full set, or sets, instead of passing event by event, for example:

```console
tracker --events syscalls
```
or 

```console
tracker --events syscalls,network_events
```


## Read in CLI

You can view the list of available events and their schema by running `tracker list` command.

## Read in AVD

[KhulnaSoft Vulnerability Database (AVD)](https://avd.khulnasoft.com) is a public index of all security information that can be reported across all of KhulnaSoft's products and tools. As such, it also contains entries about Tracker security events. The AVD entries on runtime security are generated from the [detection signatures](https://github.com/khulnasoft-labs/tracker/tree/main/signatures) and are organized by MITRE ATT&CK categorization. Browse at [avd.khulnasoft.com/tracker](https://avd.khulnasoft.com/tracker/).

👈 Please use the side-navigation on the left in order to browse the different topics.

[filters]: ../../filters/filtering
[policies]: ../../policies
