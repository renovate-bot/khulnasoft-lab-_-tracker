package main

import (
	"fmt"

	"github.com/khulnasoft-lab/tracker/signatures/helpers"
	"github.com/khulnasoft-lab/tracker/types/detect"
	"github.com/khulnasoft-lab/tracker/types/protocol"
	"github.com/khulnasoft-lab/tracker/types/trace"
)

type e2eFtraceHook struct {
	cb detect.SignatureHandler
}

func (sig *e2eFtraceHook) Init(ctx detect.SignatureContext) error {
	sig.cb = ctx.Callback
	return nil
}

func (sig *e2eFtraceHook) GetMetadata() (detect.SignatureMetadata, error) {
	return detect.SignatureMetadata{
		ID:          "FTRACE_HOOK",
		EventName:   "FTRACE_HOOK",
		Version:     "0.1.0",
		Name:        "ftrace_hook Test",
		Description: "Instrumentation events E2E Tests: ftrace_hook",
		Tags:        []string{"e2e", "instrumentation"},
	}, nil
}

func (sig *e2eFtraceHook) GetSelectedEvents() ([]detect.SignatureEventSelector, error) {
	return []detect.SignatureEventSelector{
		{Source: "tracker", Name: "ftrace_hook"},
	}, nil
}

func (sig *e2eFtraceHook) OnEvent(event protocol.Event) error {
	eventObj, ok := event.Payload.(trace.Event)
	if !ok {
		return fmt.Errorf("failed to cast event's payload")
	}

	switch eventObj.EventName {
	case "ftrace_hook":
		symbolName, err := helpers.GetTrackerStringArgumentByName(eventObj, "symbol")
		if err != nil {
			return err
		}

		if symbolName != "commit_creds" {
			return nil
		}

		m, _ := sig.GetMetadata()
		sig.cb(&detect.Finding{
			SigMetadata: m,
			Event:       event,
			Data:        map[string]interface{}{},
		})
	}

	return nil
}

func (sig *e2eFtraceHook) OnSignal(s detect.Signal) error {
	return nil
}

func (sig *e2eFtraceHook) Close() {}
