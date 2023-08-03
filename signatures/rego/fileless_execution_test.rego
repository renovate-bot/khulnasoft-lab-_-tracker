package tracker.TRC_5

test_match_1 {
	tracker_match with input as {
		"eventName": "sched_process_exec",
		"argsNum": 1,
		"containerId": "someContainer",
		"args": [{
			"name": "pathname",
			"value": "memfd://something/something",
		}],
	}
}

test_match_2 {
	tracker_match with input as {
		"eventName": "sched_process_exec",
		"argsNum": 1,
		"containerId": "someContainer",
		"args": [{
			"name": "pathname",
			"value": "memfd:runc",
		}],
	}
}

test_match_3 {
	tracker_match with input as {
		"eventName": "sched_process_exec",
		"argsNum": 1,
		"containerId": "",
		"args": [{
			"name": "pathname",
			"value": "memfd://something/something",
		}],
	}
}

test_match_4 {
	not tracker_match with input as {
		"eventName": "sched_process_exec",
		"argsNum": 1,
		"containerId": "",
		"args": [{
			"name": "pathname",
			"value": "memfd:runc",
		}],
	}
}

test_match_5 {
	tracker_match with input as {
		"eventName": "sched_process_exec",
		"argsNum": 1,
		"containerId": "someContainer",
		"args": [{
			"name": "pathname",
			"value": "/dev/shm/something",
		}],
	}
}

test_match_6 {
	tracker_match with input as {
		"eventName": "sched_process_exec",
		"argsNum": 1,
		"containerId": "someContainer",
		"args": [{
			"name": "pathname",
			"value": "/run/shm/something",
		}],
	}
}

test_match_wrong_pathname {
	not tracker_match with input as {
		"eventName": "sched_process_exec",
		"argsNum": 1,
		"containerId": "someContainer",
		"args": [{
			"name": "pathname",
			"value": "/something/something",
		}],
	}
}
