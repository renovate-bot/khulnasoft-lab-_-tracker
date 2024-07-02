package main

import (
	"fmt"
	"strings"

	"github.com/khulnasoft-lab/tracker/signatures/helpers"
	"github.com/khulnasoft-lab/tracker/types/detect"
	"github.com/khulnasoft-lab/tracker/types/protocol"
	"github.com/khulnasoft-lab/tracker/types/trace"
)

type HiddenFileCreated struct {
	cb                detect.SignatureHandler
	hiddenPathPattern string
}

func (sig *HiddenFileCreated) Init(ctx detect.SignatureContext) error {
	sig.cb = ctx.Callback
	sig.hiddenPathPattern = "/."
	return nil
}

func (sig *HiddenFileCreated) GetMetadata() (detect.SignatureMetadata, error) {
	return detect.SignatureMetadata{
		ID:          "TRC-1015",
		Version:     "1",
		Name:        "Hidden executable creation detected",
		EventName:   "hidden_file_created",
		Description: "A hidden executable (ELF file) was created on disk. This activity could be legitimate; however, it could indicate that an adversary is trying to avoid detection by hiding their programs.",
		Properties: map[string]interface{}{
			"Severity":             2,
			"Category":             "defense-evasion",
			"Technique":            "Hidden Files and Directories",
			"Kubernetes_Technique": "",
			"id":                   "attack-pattern--ec8fc7e2-b356-455c-8db5-2e37be158e7d",
			"external_id":          "T1564.001",
		},
	}, nil
}

func (sig *HiddenFileCreated) GetSelectedEvents() ([]detect.SignatureEventSelector, error) {
	return []detect.SignatureEventSelector{
		{Source: "tracker", Name: "magic_write", Origin: "*"},
	}, nil
}

func (sig *HiddenFileCreated) OnEvent(event protocol.Event) error {
	eventObj, ok := event.Payload.(trace.Event)
	if !ok {
		return fmt.Errorf("invalid event")
	}

	switch eventObj.EventName {
	case "magic_write":
		bytes, err := helpers.GetTrackerBytesSliceArgumentByName(eventObj, "bytes")
		if err != nil {
			return err
		}

		pathname, err := helpers.GetTrackerStringArgumentByName(eventObj, "pathname")
		if err != nil {
			return err
		}

		if helpers.IsElf(bytes) && strings.Contains(pathname, sig.hiddenPathPattern) {
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

func (sig *HiddenFileCreated) OnSignal(s detect.Signal) error {
	return nil
}
func (sig *HiddenFileCreated) Close() {}
