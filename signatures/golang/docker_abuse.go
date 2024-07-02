package main

import (
	"fmt"
	"strings"

	"github.com/khulnasoft-lab/tracker/signatures/helpers"
	"github.com/khulnasoft-lab/tracker/types/detect"
	"github.com/khulnasoft-lab/tracker/types/protocol"
	"github.com/khulnasoft-lab/tracker/types/trace"
)

type DockerAbuse struct {
	cb         detect.SignatureHandler
	dockerSock string
}

func (sig *DockerAbuse) Init(ctx detect.SignatureContext) error {
	sig.cb = ctx.Callback
	sig.dockerSock = "docker.sock"
	return nil
}

func (sig *DockerAbuse) GetMetadata() (detect.SignatureMetadata, error) {
	return detect.SignatureMetadata{
		ID:          "TRC-1019",
		Version:     "1",
		Name:        "Docker socket abuse detected",
		EventName:   "docker_abuse",
		Description: "An attempt to abuse the Docker UNIX socket inside a container was detected. docker.sock is the UNIX socket that Docker uses as the entry point to the Docker API. Adversaries may attempt to abuse this socket to compromise the system.",
		Properties: map[string]interface{}{
			"Severity":             2,
			"Category":             "privilege-escalation",
			"Technique":            "Exploitation for Privilege Escalation",
			"Kubernetes_Technique": "",
			"id":                   "attack-pattern--b21c3b2d-02e6-45b1-980b-e69051040839",
			"external_id":          "T1068",
		},
	}, nil
}

func (sig *DockerAbuse) GetSelectedEvents() ([]detect.SignatureEventSelector, error) {
	return []detect.SignatureEventSelector{
		{Source: "tracker", Name: "security_file_open", Origin: "container"},
		{Source: "tracker", Name: "security_socket_connect", Origin: "container"},
	}, nil
}

func (sig *DockerAbuse) OnEvent(event protocol.Event) error {
	eventObj, ok := event.Payload.(trace.Event)
	if !ok {
		return fmt.Errorf("invalid event")
	}

	path := ""

	switch eventObj.EventName {
	case "security_file_open":
		pathname, err := helpers.GetTrackerStringArgumentByName(eventObj, "pathname")
		if err != nil {
			return err
		}

		flags, err := helpers.GetTrackerStringArgumentByName(eventObj, "flags")
		if err != nil {
			return err
		}

		if helpers.IsFileWrite(flags) {
			path = pathname
		}
	case "security_socket_connect":
		addr, err := helpers.GetRawAddrArgumentByName(eventObj, "remote_addr")
		if err != nil {
			return err
		}

		supportedFamily, err := helpers.IsUnixFamily(addr)
		if err != nil {
			return err
		}
		if !supportedFamily {
			return nil
		}

		sunPath, err := helpers.GetPathFromRawAddr(addr)
		if err != nil {
			return err
		}

		path = sunPath
	}

	if strings.HasSuffix(path, sig.dockerSock) {
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

	return nil
}

func (sig *DockerAbuse) OnSignal(s detect.Signal) error {
	return nil
}
func (sig *DockerAbuse) Close() {}
