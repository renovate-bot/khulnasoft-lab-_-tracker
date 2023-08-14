//go:build ebpf
// +build ebpf

package tracker

import (
	"embed"
)

//go:embed "dist/tracker.bpf.o"
//go:embed "dist/btfhub/*"

var BPFBundleInjected embed.FS
