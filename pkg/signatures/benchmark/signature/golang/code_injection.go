package golang

import (
	"fmt"
	"regexp"

	"github.com/khulnasoft-lab/tracker/signatures/helpers"
	"github.com/khulnasoft-lab/tracker/types/detect"
	"github.com/khulnasoft-lab/tracker/types/protocol"
	"github.com/khulnasoft-lab/tracker/types/trace"
)

type codeInjection struct {
	processMemFileRegexp *regexp.Regexp
	cb                   detect.SignatureHandler
	metadata             detect.SignatureMetadata
}

func NewCodeInjectionSignature() (detect.Signature, error) {
	processMemFileRegexp, err := regexp.Compile(`/proc/(?:\d.+|self)/mem`)
	if err != nil {
		return nil, err
	}
	return &codeInjection{
		processMemFileRegexp: processMemFileRegexp,
		metadata: detect.SignatureMetadata{
			Name:        "Code injection",
			Description: "Possible process injection detected during runtime",
			Tags:        []string{"linux", "container"},
			Properties: map[string]interface{}{
				"Severity":     3,
				"MITRE ATT&CK": "Defense Evasion: Process Injection",
			},
		},
	}, nil
}

func (sig *codeInjection) Init(ctx detect.SignatureContext) error {
	sig.cb = ctx.Callback
	return nil
}

func (sig *codeInjection) GetMetadata() (detect.SignatureMetadata, error) {
	return sig.metadata, nil
}

func (sig *codeInjection) GetSelectedEvents() ([]detect.SignatureEventSelector, error) {
	return []detect.SignatureEventSelector{
		{Source: "tracker", Name: "ptrace"},
		{Source: "tracker", Name: "open"},
		{Source: "tracker", Name: "openat"},
		{Source: "tracker", Name: "execve"},
	}, nil
}

func (sig *codeInjection) OnEvent(event protocol.Event) error {
	// event example:
	// { "eventName": "ptrace", "args": [{"name": "request", "value": "PTRACE_POKETEXT" }]}
	// { "eventName": "open", "args": [{"name": "flags", "value": "o_wronly" }, {"name": "pathname", "value": "/proc/self/mem" }]}
	// { "eventName": "execve" args": [{"name": "envp", "value": ["FOO=BAR", "LD_PRELOAD=/something"] }, {"name": "argv", "value": ["ls"] }]}
	ee, ok := event.Payload.(trace.Event)

	if !ok {
		return fmt.Errorf("failed to cast event's payload")
	}
	switch ee.EventName {
	case "open", "openat":
		flags, err := helpers.GetTrackerArgumentByName(ee, "flags", helpers.GetArgOps{DefaultArgs: false})
		if err != nil {
			return fmt.Errorf("%v %#v", err, ee)
		}
		if helpers.IsFileWrite(flags.Value.(string)) {
			pathname, err := helpers.GetTrackerArgumentByName(ee, "pathname", helpers.GetArgOps{DefaultArgs: false})
			if err != nil {
				return err
			}
			if sig.processMemFileRegexp.MatchString(pathname.Value.(string)) {
				sig.cb(&detect.Finding{
					// Signature: sig,
					SigMetadata: sig.metadata,
					Event:       event,
					Data: map[string]interface{}{
						"file flags": flags,
						"file path":  pathname.Value.(string),
					},
				})
			}
		}
	case "ptrace":
		request, err := helpers.GetTrackerArgumentByName(ee, "request", helpers.GetArgOps{DefaultArgs: false})
		if err != nil {
			return err
		}

		requestString, ok := request.Value.(string)
		if !ok {
			return fmt.Errorf("failed to cast request's value")
		}

		if requestString == "PTRACE_POKETEXT" || requestString == "PTRACE_POKEDATA" {
			sig.cb(&detect.Finding{
				// Signature: sig,
				SigMetadata: sig.metadata,
				Event:       event,
				Data: map[string]interface{}{
					"ptrace request": requestString,
				},
			})
		}
		// TODO Commenting out the execve case to make it equivalent to Rego signature
		//
		// case "execve":
		//	envs, err := helpers.GetTrackerArgumentByName(ee, "envp", helpers.GetArgOps{DefaultArgs: false})
		//	if err != nil {
		//		break
		//	}
		//	envsSlice := envs.Value.([]string)
		//	for _, env := range envsSlice {
		//		if strings.HasPrefix(env, "LD_PRELOAD") || strings.HasPrefix(env, "LD_LIBRARY_PATH") {
		//			cmd, err := helpers.GetTrackerArgumentByName(ee, "argv", helpers.GetArgOps{DefaultArgs: false})
		//			if err != nil {
		//				return err
		//			}
		//			sig.cb(&detect.Finding{
		// Signature: sig,
		//				SigMetadata: sig.metadata,
		//				Payload:     ee,
		//				Data: map[string]interface{}{
		//					"command":     cmd,
		//					"command env": env,
		//				},
		//			})
		//		}
		//	}
	}
	return nil
}

func (sig *codeInjection) OnSignal(s detect.Signal) error {
	return nil
}
func (sig *codeInjection) Close() {}
