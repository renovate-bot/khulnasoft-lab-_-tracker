package tracker.TRC_6

test_match_1 {
	tracker_match with input as {
		"eventName": "init_module",
		"argsNum": 0,
	}
}

test_match_2 {
	tracker_match with input as {
		"eventName": "security_kernel_read_file",
		"argsNum": 4,
		"args": [
			{
				"name": "pathname",
				"value": "/path/to/kernel/module.ko",
			},
			{
				"name": "dev",
				"value": 100,
			},
			{
				"name": "inode",
				"value": 4026532486,
			},
			{
				"name": "type",
				"value": "kernel-module",
			},
		],
	}
}

test_match_deprecated_event {
	not tracker_match with input as {
		"eventName": "finit_module",
		"argsNum": 0,
	}
}

test_match_wrong_event {
	not tracker_match with input as {
		"eventName": "ptrace",
		"argsNum": 1,
		"args": [{
			"name": "request",
			"value": "PTRACE_PEEKDATA",
		}],
	}
}

test_match_wrong_type {
	not tracker_match with input as {
		"eventName": "security_kernel_read_file",
		"argsNum": 4,
		"args": [
			{
				"name": "pathname",
				"value": "/path/to/kernel/module.ko",
			},
			{
				"name": "dev",
				"value": 100,
			},
			{
				"name": "inode",
				"value": 4026532486,
			},
			{
				"name": "type",
				"value": "security-policy",
			},
		],
	}
}
