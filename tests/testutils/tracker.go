package testutils

import (
	"context"
	"fmt"
	"net/http"
	"os/exec"
	"strings"
	"time"
)

//
// RunningTrace
//

const (
	readinessPollTime            = 200 * time.Millisecond
	httpRequestTimeout           = 1 * time.Second
	TrackerDefaultStartupTimeout = 5 * time.Second
)

var (
	TrackerBinary   = "../../dist/tracker"
	TrackerHostname = "localhost"
	TrackerPort     = 3366
)

type TrackerStatus int

const (
	TrackerStarted TrackerStatus = iota
	TrackerFailed
	TrackerTimedout
	TrackerAlreadyRunning
)

// RunningTracker is a wrapper for a running tracker process as a regular process.
type RunningTracker struct {
	ctx       context.Context
	cancel    context.CancelFunc
	cmdStatus chan error
	cmdLine   string
	pid       int
	isReady   chan TrackerStatus
}

// NewRunningTracker creates a new RunningTracker instance.
func NewRunningTracker(givenCtx context.Context, cmdLine string) *RunningTracker {
	ctx, cancel := context.WithCancel(givenCtx)

	// Add healthz flag if not present (required for readiness check)
	if !strings.Contains(cmdLine, "--healthz") {
		cmdLine = fmt.Sprintf("--healthz %s", cmdLine)
	}

	cmdLine = fmt.Sprintf("%s %s", TrackerBinary, cmdLine)

	return &RunningTracker{
		ctx:     ctx,
		cancel:  cancel,
		cmdLine: cmdLine,
	}
}

// Start starts the tracker process.
func (r *RunningTracker) Start(timeout time.Duration) (<-chan TrackerStatus, error) {
	var err error

	imReady := func(s TrackerStatus) {
		go func(s TrackerStatus) {
			r.isReady <- s // blocks until someone reads
		}(s)
	}

	r.isReady = make(chan TrackerStatus)
	now := time.Now()

	if isTrackerAlreadyRunning() { // check if tracker is already running
		imReady(TrackerAlreadyRunning) // ready: already running
		goto exit
	}

	r.pid, r.cmdStatus, err = ExecCmdBgWithSudoAndCtx(r.ctx, r.cmdLine)
	if err != nil {
		imReady(TrackerFailed) // ready: failed
		goto exit
	}

	for {
		time.Sleep(readinessPollTime)
		if r.IsReady() {
			imReady(TrackerStarted) // ready: running
			break
		}
		if time.Since(now) > timeout {
			imReady(TrackerTimedout) // ready: timedout
			break
		}
	}

exit:
	return r.isReady, err
}

// Stop stops the tracker process.
func (r *RunningTracker) Stop() []error {
	if r.pid == 0 {
		return nil // cmd was never started
	}

	r.cancel()
	var errs []error
	for err := range r.cmdStatus {
		errs = append(errs, err)
	}
	return errs
}

// IsReady checks if the tracker process is ready.
func (r *RunningTracker) IsReady() bool {
	ctx, cancel := context.WithTimeout(context.Background(), httpRequestTimeout)
	defer cancel()

	client := http.Client{
		Timeout: httpRequestTimeout,
	}

	// Create the request
	req, err := http.NewRequestWithContext(ctx, "GET",
		fmt.Sprintf("http://%s:%d/healthz", TrackerHostname, TrackerPort),
		nil,
	)
	if err != nil {
		return false
	}

	// Do the request
	resp, err := client.Do(req)
	if err != nil {
		return false
	}
	_ = resp.Body.Close()

	// Only 200 is considered ready
	return resp.StatusCode == 200
}

// isTrackerAlreadyRunning checks if tracker is already running.
func isTrackerAlreadyRunning() bool {
	cmd := exec.Command("pgrep", "tracker")
	cmd.Stderr = nil
	cmd.Stdout = nil

	err := cmd.Run()

	return err == nil
}
