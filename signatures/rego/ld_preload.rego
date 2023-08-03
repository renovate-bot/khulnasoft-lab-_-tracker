package tracker.TRC_7

import data.tracker.helpers

__rego_metadoc__ := {
	"id": "TRC-7",
	"version": "0.1.0",
	"name": "LD_PRELOAD",
	"eventName": "ld_preload",
	"description": "Usage of LD_PRELOAD to allow hooks on process",
	"tags": ["linux", "container"],
	"properties": {
		"Severity": 2,
		"MITRE ATT&CK": "Persistence: Hijack Execution Flow",
	},
}

eventSelectors := [
	{
		"source": "tracker",
		"name": "execve",
	},
	{
		"source": "tracker",
		"name": "security_file_open",
	},
]

tracker_selected_events[eventSelector] {
	eventSelector := eventSelectors[_]
}

tracker_match {
	input.eventName == "execve"
	envp = helpers.get_tracker_argument("envp")

	envvar := envp[_]
	startswith(envvar, "LD_PRELOAD")
}

tracker_match {
	input.eventName == "execve"
	envp = helpers.get_tracker_argument("envp")

	envvar := envp[_]
	startswith(envvar, "LD_LIBRARY_PATH")
}

tracker_match {
	input.eventName == "security_file_open"
	flags = helpers.get_tracker_argument("flags")

	helpers.is_file_write(flags)

	pathname := helpers.get_tracker_argument("pathname")

	pathname == "/etc/ld.so.preload"
}
