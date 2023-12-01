package tracker.TRC_15

test_match_diamorphine_rootkit_output {
	tracker_match with input as {
		"eventName": "hooked_syscall",
		"argsNum": 1,
		"args": [{
			"name": "hooked_syscall",
			"value": {"syscall_name": "kill", "hooked.owner": "diamorphine"},
		}],
	}
}
