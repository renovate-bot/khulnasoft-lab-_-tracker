package main

import "github.com/khulnasoft-lab/tracker/types/detect"

var ExportedSignatures = []detect.Signature{
	// Instrumentation e2e signatures
	&e2eVfsWrite{},
	&e2eFileModification{},
	&e2eSecurityInodeRename{},
	&e2eContainersDataSource{},
	&e2eBpfAttach{},
}
