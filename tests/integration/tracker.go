package integration

import (
	"context"
	"fmt"
	"path/filepath"
	"strconv"
	"sync"
	"syscall"
	"testing"
	"time"

	"github.com/khulnasoft-lab/tracker/pkg/cmd/initialize"
	"github.com/khulnasoft-lab/tracker/pkg/config"
	tracker "github.com/khulnasoft-lab/tracker/pkg/ebpf"
	"github.com/khulnasoft-lab/tracker/pkg/proctree"
	"github.com/khulnasoft-lab/tracker/pkg/utils/environment"
	uproc "github.com/khulnasoft-lab/tracker/pkg/utils/proc"
	"github.com/khulnasoft-lab/tracker/types/trace"
)

// eventBuffer is a thread-safe buffer for tracker events
type eventBuffer struct {
	mu     sync.RWMutex
	events []trace.Event
}

func newEventBuffer() *eventBuffer {
	return &eventBuffer{
		events: make([]trace.Event, 0),
	}
}

// addEvent adds an event to the eventBuffer
func (b *eventBuffer) addEvent(evt trace.Event) {
	b.mu.Lock()
	defer b.mu.Unlock()

	b.events = append(b.events, evt)
}

// clear clears the eventBuffer
func (b *eventBuffer) clear() {
	b.mu.Lock()
	defer b.mu.Unlock()

	b.events = make([]trace.Event, 0)
}

// len returns the number of events in the eventBuffer
func (b *eventBuffer) len() int {
	b.mu.RLock()
	defer b.mu.RUnlock()

	return len(b.events)
}

// getCopy returns a copy of the eventBuffer events
func (b *eventBuffer) getCopy() []trace.Event {
	b.mu.RLock()
	defer b.mu.RUnlock()

	evts := make([]trace.Event, len(b.events))
	copy(evts, b.events)

	return evts
}

// load tracker into memory with args
func startTracker(ctx context.Context, t *testing.T, cfg config.Config, output *config.OutputConfig, capture *config.CaptureConfig) (*tracker.Tracker, error) {
	initialize.SetLibbpfgoCallbacks()

	kernelConfig, err := initialize.KernelConfig()
	if err != nil {
		return nil, err
	}

	cfg.KernelConfig = kernelConfig

	osInfo, err := environment.GetOSInfo()
	if err != nil {
		return nil, err
	}

	err = initialize.BpfObject(&cfg, kernelConfig, osInfo, "/tmp/tracker", "")
	if err != nil {
		return nil, err
	}

	if capture == nil {
		capture = prepareCapture()
	}

	cfg.Capture = capture

	cfg.PerfBufferSize = 1024
	cfg.BlobPerfBufferSize = 1024

	// No process tree in the integration tests
	cfg.ProcTree = proctree.ProcTreeConfig{
		Source: proctree.SourceNone,
	}

	errChan := make(chan error)

	go func() {
		for {
			select {
			case err, ok := <-errChan:
				if !ok {
					return
				}
				t.Logf("received error while testing: %s\n", err)
			case <-ctx.Done():
				return
			}
		}
	}()

	if output == nil {
		output = &config.OutputConfig{}
	}

	cfg.Output = output
	cfg.NoContainersEnrich = true

	trc, err := tracker.New(cfg)
	if err != nil {
		return nil, err
	}

	err = trc.Init(ctx)
	if err != nil {
		return nil, err
	}

	go func() {
		err := trc.Run(ctx)
		if err != nil {
			errChan <- fmt.Errorf("error while running tracker: %s", err)
		}
	}()

	return trc, nil
}

// prepareCapture prepares a capture config for tracker
func prepareCapture() *config.CaptureConfig {
	// taken from tracker-rule github project, might have to adjust...
	// prepareCapture is called with nil input
	return &config.CaptureConfig{
		FileWrite: config.FileCaptureConfig{
			PathFilter: []string{},
		},
		OutputPath: filepath.Join("/tmp/tracker", "out"),
	}
}

// wait for tracker to start (or timeout)
// in case of timeout, the test will fail
func waitForTrackerStart(trc *tracker.Tracker) error {
	const timeout = 10 * time.Second

	statusCheckTicker := time.NewTicker(1 * time.Second)
	defer statusCheckTicker.Stop()
	timeoutTicker := time.NewTicker(timeout)
	defer timeoutTicker.Stop()

	for {
		select {
		case <-statusCheckTicker.C:
			if trc.Running() {
				return nil
			}
		case <-timeoutTicker.C:
			return fmt.Errorf("timed out on waiting for tracker to start")
		}
	}
}

// wait for tracker to stop (or timeout)
// in case of timeout, the test will continue since all tests already passed
func waitForTrackerStop(trc *tracker.Tracker) error {
	const timeout = 10 * time.Second

	statusCheckTicker := time.NewTicker(1 * time.Second)
	defer statusCheckTicker.Stop()
	timeoutTicker := time.NewTicker(timeout)
	defer timeoutTicker.Stop()

	for {
		select {
		case <-statusCheckTicker.C:
			if !trc.Running() {
				return nil
			}
		case <-timeoutTicker.C:
			return fmt.Errorf("timed out on stopping tracker")
		}
	}
}

// wait for tracker buffer to fill up with expected number of events (or timeout)
// in case of timeout, the test will fail
func waitForTrackerOutputEvents(t *testing.T, waitFor time.Duration, actual *eventBuffer, expectedEvts int, failOnTimeout bool) error {
	if waitFor > 0 {
		t.Logf("  . waiting events collection for %s", waitFor.String())
		time.Sleep(waitFor)
	}

	const timeout = 5 * time.Second

	statusCheckTicker := time.NewTicker(1 * time.Second)
	defer statusCheckTicker.Stop()
	timeoutTicker := time.NewTicker(timeout)
	defer timeoutTicker.Stop()

	t.Logf("  . waiting for at least %d event(s) for %s", expectedEvts, timeout.String())
	defer t.Logf("  . done waiting for %d event(s)", expectedEvts)

	for {
		select {
		case <-statusCheckTicker.C:
			len := actual.len()
			t.Logf("  . got %d event(s) so far", len)
			if len >= expectedEvts {
				return nil
			}
		case <-timeoutTicker.C:
			if failOnTimeout {
				return fmt.Errorf("timed out on waiting for %d event(s)", expectedEvts)
			}
			return nil
		}
	}
}

// assureIsRoot skips the test if it is not run as root
func assureIsRoot(t *testing.T) {
	if syscall.Geteuid() != 0 {
		t.Skipf("***** %s must be run as ROOT *****", t.Name())
	}
}

func getProcNS(nsName string) string {
	pid := syscall.Getpid()
	nsID, err := uproc.GetProcNS(uint(pid), nsName)
	if err != nil {
		panic(err)
	}

	return strconv.Itoa(nsID)
}
