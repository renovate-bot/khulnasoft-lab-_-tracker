package main

import (
	"fmt"
	"path"

	"github.com/khulnasoft-lab/tracker/signatures/helpers"
	"github.com/khulnasoft-lab/tracker/types/detect"
	"github.com/khulnasoft-lab/tracker/types/protocol"
	"github.com/khulnasoft-lab/tracker/types/trace"
)

type CgroupNotifyOnReleaseModification struct {
	cb             detect.SignatureHandler
	notifyFileName string
}

func (sig *CgroupNotifyOnReleaseModification) Init(ctx detect.SignatureContext) error {
	sig.cb = ctx.Callback
	sig.notifyFileName = "notify_on_release"
	return nil
}

func (sig *CgroupNotifyOnReleaseModification) GetMetadata() (detect.SignatureMetadata, error) {
	return detect.SignatureMetadata{
		ID:          "TRC-106",
		Version:     "1",
		Name:        "Cgroups notify_on_release file modification",
		EventName:   "cgroup_notify_on_release",
		Description: "An attempt to modify Cgroup notify_on_release file was detected. Cgroups are a Linux kernel feature which limits the resource usage of a set of processes. Adversaries may use this feature for container escaping.",
		Properties: map[string]interface{}{
			"Severity":             3,
			"Category":             "privilege-escalation",
			"Technique":            "Escape to Host",
			"Kubernetes_Technique": "",
			"id":                   "attack-pattern--4a5b7ade-8bb5-4853-84ed-23f262002665",
			"external_id":          "T1611",
		},
	}, nil
}

func (sig *CgroupNotifyOnReleaseModification) GetSelectedEvents() ([]detect.SignatureEventSelector, error) {
	return []detect.SignatureEventSelector{
		{Source: "tracker", Name: "security_file_open", Origin: "container"},
	}, nil
}

func (sig *CgroupNotifyOnReleaseModification) OnEvent(event protocol.Event) error {
	eventObj, ok := event.Payload.(trace.Event)
	if !ok {
		return fmt.Errorf("invalid event")
	}

	switch eventObj.EventName {
	case "security_file_open":
		pathname, err := helpers.GetTrackerStringArgumentByName(eventObj, "pathname")
		if err != nil {
			return err
		}
		basename := path.Base(pathname)

		flags, err := helpers.GetTrackerStringArgumentByName(eventObj, "flags")
		if err != nil {
			return err
		}

		if basename == sig.notifyFileName && helpers.IsFileWrite(flags) {
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

func (sig *CgroupNotifyOnReleaseModification) OnSignal(s detect.Signal) error {
	return nil
}
func (sig *CgroupNotifyOnReleaseModification) Close() {}
