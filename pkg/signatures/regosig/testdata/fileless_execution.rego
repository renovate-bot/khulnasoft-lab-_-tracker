package tracker.TRC_5

import data.tracker.helpers

__rego_metadoc__ := {
	"id": "TRC-5",
	"version": "0.1.0",
	"name": "Fileless Execution",
	"description": "Executing a process from memory, without a file in the disk",
	"tags": ["linux", "container"],
	"properties": {
		"Severity": 2,
		"MITRE ATT&CK": "Defense Evasion: Obfuscated Files or Information",
	},
}

eventSelectors := [{
	"source": "tracker",
	"name": "sched_process_exec",
}]

tracker_selected_events[eventSelector] {
	eventSelector := eventSelectors[_]
}

tracker_match {
	input.eventName == "sched_process_exec"
	pathname = helpers.get_tracker_argument("pathname")
	startswith(pathname, "memfd:")

	not startswith(pathname, "memfd:runc")
	input.containerId == ""
}

tracker_match {
	input.eventName == "sched_process_exec"
	pathname = helpers.get_tracker_argument("pathname")
	startswith(pathname, "memfd:")

	input.containerId != ""
}

tracker_match {
	input.eventName == "sched_process_exec"
	pathname = helpers.get_tracker_argument("pathname")
	startswith(pathname, "/dev/shm")
}

tracker_match {
	input.eventName == "sched_process_exec"
	pathname = helpers.get_tracker_argument("pathname")
	startswith(pathname, "/run/shm")
}
