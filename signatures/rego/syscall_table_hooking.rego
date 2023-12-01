package tracker.TRC_15

import data.tracker.helpers

__rego_metadoc__ := {
	"id": "TRC-15",
	"version": "0.1.0",
	"name": "Hooking system calls by overriding the system call table entries",
	"eventName": "syscall_hooking",
	"description": "Usage of kernel modules to hook system calls",
	"tags": ["linux"],
	"properties": {
		"Severity": 4,
		"MITRE ATT&CK": "Persistence: Hooking system calls entries in the system-call table",
	},
}

eventSelectors := [{
	"source": "tracker",
	"name": "hooked_syscall",
}]

tracker_selected_events[eventSelector] {
	eventSelector := eventSelectors[_]
}

tracker_match {
	input.eventName == "hooked_syscall"
}
