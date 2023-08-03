package tracker.TRC_11

test_match_1 {
	tracker_match with input as {
		"processName": "mal",
		"threadId": 8,
		"eventName": "security_sb_mount",
		"argsNum": 1,
		"args": [{
			"name": "dev_name",
			"type": "const char*",
			"value": "/dev/sda3",
		}],
	}
}

test_match_2 {
	tracker_match with input as {
		"processName": "runc:[init]",
		"threadId": 8,
		"eventName": "security_sb_mount",
		"argsNum": 1,
		"args": [{
			"name": "dev_name",
			"type": "const char*",
			"value": "/dev/vda1",
		}],
	}
}

test_match_wrong_device {
	not tracker_match with input as {
		"processName": "proc",
		"threadId": 8,
		"eventName": "security_sb_mount",
		"argsNum": 1,
		"args": [{
			"name": "dev_name",
			"type": "const char*",
			"value": "/disk",
		}],
	}
}

test_match_wrong_proc {
	not tracker_match with input as {
		"processName": "runc:[init]",
		"threadId": 1,
		"eventName": "security_sb_mount",
		"argsNum": 1,
		"args": [{
			"name": "dev_name",
			"type": "const char*",
			"value": "/dev/vda1",
		}],
	}
}
