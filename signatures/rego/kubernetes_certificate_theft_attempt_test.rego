package tracker.TRC_10

test_match_1 {
	tracker_match with input as {
		"eventName": "security_file_open",
		"processName": "malware",
		"args": [
			{
				"name": "flags",
				"value": "O_RDONLY",
			},
			{
				"name": "pathname",
				"value": "/etc/kubernetes/pki/ca.crt",
			},
		],
	}
}

test_match_wrong_request {
	not tracker_match with input as {
		"eventName": "security_file_open",
		"processName": "kubelet",
		"args": [
			{
				"name": "flags",
				"value": "O_RDONLY",
			},
			{
				"name": "pathname",
				"value": "/etc/kubernetes/pki/ca.crt",
			},
		],
	}
}
