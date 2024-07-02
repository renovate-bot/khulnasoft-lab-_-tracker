package main

import (
	"fmt"
	"strings"

	"github.com/khulnasoft-lab/tracker/signatures/helpers"
	"github.com/khulnasoft-lab/tracker/types/detect"
	"github.com/khulnasoft-lab/tracker/types/protocol"
	"github.com/khulnasoft-lab/tracker/types/trace"
)

type LdPreload struct {
	cb          detect.SignatureHandler
	preloadEnvs []string
	preloadPath string
}

func (sig *LdPreload) Init(ctx detect.SignatureContext) error {
	sig.cb = ctx.Callback
	sig.preloadEnvs = []string{"LD_PRELOAD", "LD_LIBRARY_PATH"}
	sig.preloadPath = "/etc/ld.so.preload"
	return nil
}

func (sig *LdPreload) GetMetadata() (detect.SignatureMetadata, error) {
	return detect.SignatureMetadata{
		ID:          "TRC-107",
		Version:     "1",
		Name:        "LD_PRELOAD code injection detected",
		EventName:   "ld_preload",
		Description: "LD_PRELOAD usage was detected. LD_PRELOAD lets you load your library before any other library, allowing you to hook functions in a process. Adversaries may use this technique to change your applications' behavior or load their own programs.",
		Properties: map[string]interface{}{
			"Severity":             2,
			"Category":             "persistence",
			"Technique":            "Hijack Execution Flow",
			"Kubernetes_Technique": "",
			"id":                   "attack-pattern--aedfca76-3b30-4866-b2aa-0f1d7fd1e4b6",
			"external_id":          "T1574",
		},
	}, nil
}

func (sig *LdPreload) GetSelectedEvents() ([]detect.SignatureEventSelector, error) {
	return []detect.SignatureEventSelector{
		{Source: "tracker", Name: "sched_process_exec", Origin: "*"},
		{Source: "tracker", Name: "security_file_open", Origin: "*"},
		{Source: "tracker", Name: "security_inode_rename", Origin: "*"},
	}, nil
}

func (sig *LdPreload) OnEvent(event protocol.Event) error {
	eventObj, ok := event.Payload.(trace.Event)
	if !ok {
		return fmt.Errorf("invalid event")
	}

	switch eventObj.EventName {
	case "sched_process_exec":
		envVars, err := helpers.GetTrackerSliceStringArgumentByName(eventObj, "env")
		if err != nil {
			return nil
		}

		for _, envVar := range envVars {
			for _, preloadEnv := range sig.preloadEnvs {
				if strings.HasPrefix(envVar, preloadEnv+"=") {
					metadata, err := sig.GetMetadata()
					if err != nil {
						return err
					}
					sig.cb(&detect.Finding{
						SigMetadata: metadata,
						Event:       event,
						Data:        map[string]interface{}{preloadEnv: envVar},
					})

					return nil
				}
			}
		}
	case "security_file_open":
		pathname, err := helpers.GetTrackerStringArgumentByName(eventObj, "pathname")
		if err != nil {
			return err
		}

		flags, err := helpers.GetTrackerStringArgumentByName(eventObj, "flags")
		if err != nil {
			return err
		}

		if strings.HasSuffix(pathname, sig.preloadPath) && helpers.IsFileWrite(flags) {
			metadata, err := sig.GetMetadata()
			if err != nil {
				return err
			}
			sig.cb(&detect.Finding{
				SigMetadata: metadata,
				Event:       event,
				Data:        nil,
			})
		}
	case "security_inode_rename":
		newPath, err := helpers.GetTrackerStringArgumentByName(eventObj, "new_path")
		if err != nil {
			return err
		}

		if strings.HasSuffix(newPath, sig.preloadPath) {
			metadata, err := sig.GetMetadata()
			if err != nil {
				return err
			}
			sig.cb(&detect.Finding{
				SigMetadata: metadata,
				Event:       event,
				Data:        nil,
			})
		}
	}

	return nil
}

func (sig *LdPreload) OnSignal(s detect.Signal) error {
	return nil
}
func (sig *LdPreload) Close() {}
