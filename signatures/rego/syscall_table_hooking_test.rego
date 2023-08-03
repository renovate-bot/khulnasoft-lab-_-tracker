package tracker.TRC_15

test_match_diamorphine_rootkit_output {
	tracker_match with input as {
		"eventName": "hooked_syscalls",
		"argsNum": 1,
		"args": [{
			"name": "hooked_syscalls",
			"value": [{"SymbolName": "kill", "ModuleOwner": "diamorphine"}, {"SymbolName": "getdents", "ModuleOwner": "diamorphine"}, {"SymbolName": "getdents64", "ModuleOwner": "diamorphine"}],
		}],
	}
}

test_match_custom_output {
	tracker_match with input as {
		"eventName": "hooked_syscalls",
		"argsNum": 1,
		"args": [{
			"name": "hooked_syscalls",
			"value": [{"SymbolName": "open", "ModuleOwner": "diamorphine"}, {"SymbolName": "read", "ModuleOwner": "diamorphine"}],
		}],
	}
}

test_match_empty_array {
	not tracker_match with input as {
		"eventName": "hooked_syscalls",
		"argsNum": 1,
		"args": [{
			"name": "hooked_syscalls",
			"value": [],
		}],
	}
}
