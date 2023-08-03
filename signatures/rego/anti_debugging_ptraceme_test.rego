package tracker.TRC_2

test_match_1 {
	tracker_match with input as {
		"eventName": "ptrace",
		"argsNum": 1,
		"args": [{
			"name": "request",
			"value": "PTRACE_TRACEME",
		}],
	}
}

test_match_wrong_request {
	not tracker_match with input as {
		"eventName": "ptrace",
		"argsNum": 1,
		"args": [{
			"name": "request",
			"value": "PTRACE_PEEKTEXT",
		}],
	}
}
