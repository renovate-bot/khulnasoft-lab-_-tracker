package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"strings"

	"kernel.org/pub/linux/libs/security/libcap/cap"

	"github.com/khulnasoft-lab/tracker/pkg/capabilities"
	"github.com/khulnasoft-lab/tracker/pkg/errfmt"
	"github.com/khulnasoft-lab/tracker/pkg/logger"
	"github.com/khulnasoft-lab/tracker/types/protocol"
	"github.com/khulnasoft-lab/tracker/types/trace"
)

var errHelp = errfmt.Errorf("user has requested help text")

type inputFormat uint8

const (
	invalidInputFormat inputFormat = iota
	jsonInputFormat
)

type trackerInputOptions struct {
	inputFile   *os.File
	inputFormat inputFormat
}

func setupTrackerInputSource(opts *trackerInputOptions) (chan protocol.Event, error) {
	if opts.inputFormat == jsonInputFormat {
		return setupTrackerJSONInputSource(opts)
	}

	return nil, errfmt.Errorf("could not set up input source")
}

func setupTrackerJSONInputSource(opts *trackerInputOptions) (chan protocol.Event, error) {
	res := make(chan protocol.Event)
	scanner := bufio.NewScanner(opts.inputFile)
	go func() {
		for scanner.Scan() {
			event := scanner.Bytes()
			var e trace.Event
			err := json.Unmarshal(event, &e)
			if err != nil {
				logger.Errorw("Invalid json in " + string(event) + ": " + err.Error())
			} else {
				res <- e.ToProtocol()
			}
		}
		if err := opts.inputFile.Close(); err != nil {
			logger.Errorw("Closing file", "error", err)
		}
		close(res)
	}()
	return res, nil
}

func parseTrackerInputOptions(inputOptions []string) (*trackerInputOptions, error) {
	var (
		inputSourceOptions trackerInputOptions
		err                error
	)

	if len(inputOptions) == 0 {
		return nil, errfmt.Errorf("no tracker input options specified")
	}

	for i := range inputOptions {
		if inputOptions[i] == "help" {
			return nil, errHelp
		}

		kv := strings.Split(inputOptions[i], ":")
		if len(kv) != 2 {
			return nil, errfmt.Errorf("invalid input-tracker option: %s", inputOptions[i])
		}
		if kv[0] == "" || kv[1] == "" {
			return nil, errfmt.Errorf("empty key or value passed: key: >%s< value: >%s<", kv[0], kv[1])
		}
		if kv[0] == "file" {
			err = parseTrackerInputFile(&inputSourceOptions, kv[1])
			if err != nil {
				return nil, errfmt.WrapError(err)
			}
		} else if kv[0] == "format" {
			err = parseTrackerInputFormat(&inputSourceOptions, kv[1])
			if err != nil {
				return nil, errfmt.WrapError(err)
			}
		} else {
			return nil, errfmt.Errorf("invalid input-tracker option key: %s", kv[0])
		}
	}
	return &inputSourceOptions, nil
}

func parseTrackerInputFile(option *trackerInputOptions, fileOpt string) error {
	var f *os.File

	if fileOpt == "stdin" {
		option.inputFile = os.Stdin
		return nil
	}
	err := capabilities.GetInstance().Specific(
		func() error {
			_, err := os.Stat(fileOpt)
			if err != nil {
				return errfmt.Errorf("invalid Tracker input file: %s", fileOpt)
			}
			f, err = os.Open(fileOpt)
			if err != nil {
				return errfmt.Errorf("invalid file: %s", fileOpt)
			}
			return nil
		},
		cap.DAC_OVERRIDE,
	)
	if err != nil {
		return errfmt.WrapError(err)
	}
	option.inputFile = f

	return nil
}

func parseTrackerInputFormat(option *trackerInputOptions, formatString string) error {
	formatString = strings.ToUpper(formatString)

	switch formatString {
	case "JSON":
		option.inputFormat = jsonInputFormat
	default:
		option.inputFormat = invalidInputFormat
		return errfmt.Errorf("invalid tracker input format specified: %s", formatString)
	}

	return nil
}

func printHelp() {
	trackerInputHelp := `
tracker-rules --input-tracker <key:value>,<key:value> --input-tracker <key:value>

Specify various key value pairs for input options tracker-ebpf. The following key options are available:

'file'   - Input file source. You can specify a relative or absolute path. You may also specify 'stdin' for standard input.
'format' - Input format. The only supported format is 'json' at the moment.

Examples:

'tracker-rules --input-tracker file:./events.json --input-tracker format:json'
'sudo tracker-ebpf -o format:json | tracker-rules --input-tracker file:stdin --input-tracker format:json'
`

	fmt.Println(trackerInputHelp)
}
