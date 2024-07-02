package perftests

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
	"go.uber.org/goleak"

	"github.com/khulnasoft-lab/tracker/tests/testutils"
)

var metrics = []string{
	"tracker_ebpf_bpf_logs_total",
	"tracker_ebpf_errors_total",
	"tracker_ebpf_events_filtered",
	"tracker_ebpf_events_total",
	"tracker_ebpf_lostevents_total",
	"tracker_ebpf_network_capture_events_total",
	"tracker_ebpf_network_capture_lostevents_total",
	"tracker_ebpf_write_lostevents_total",
}

// checkIfMetricsExist checks if all metrics exist in the metrics endpoint.
func checkIfMetricsExist(metrics []string) error {
	resp, err := http.Get(fmt.Sprintf("http://%s:%d/metrics",
		testutils.TrackerHostname,
		testutils.TrackerPort,
	))
	if err != nil {
		fmt.Println("error making request:", err)
		return err
	}
	defer resp.Body.Close()

	// read response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Println("error reading response body:", err)
		return err
	}

	bodyStr := string(body)

	// check if all metrics exist
	for _, metric := range metrics {
		if strings.Contains(bodyStr, metric) {
			continue
		}
		return fmt.Errorf("metric %s not found", metric)
	}

	return nil
}

// checkIfPprofExist checks if all metrics exist in the metrics endpoint.
func checkIfPprofExist() error {
	resp, err := http.Get(fmt.Sprintf("http://%s:%d/debug/pprof/",
		testutils.TrackerHostname,
		testutils.TrackerPort,
	))
	if err != nil {
		fmt.Println("error making request:", err)
		return err
	}
	defer resp.Body.Close()

	// read response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Println("error reading response body:", err)
		return err
	}

	bodyStr := string(body)

	// check if pprof is enabled
	if strings.Contains(bodyStr, "Types of profiles available:") {
		return nil
	}

	return fmt.Errorf("pprof not enabled")
}

//
// Tests
//

// Note: Tests below need the following /etc/sudoers entry:
//
// ${USER} ALL=(ALL) NOPASSWD: ALL
//
// for the user running the tests.

// TestMetricsExist tests if the metrics endpoint returns all metrics.
func TestMetricsandPprofExist(t *testing.T) {
	// Make sure we don't leak any goroutines since we run Tracker many times in this test.
	// If a test case fails, ignore the leak since it's probably caused by the aborted test.
	defer goleak.VerifyNone(t)

	if !testutils.IsSudoCmdAvailableForThisUser() {
		t.Skip("skipping: sudo command is not available for this user")
	}

	cmd := "--output none --events=syslog --metrics --pprof"
	running := testutils.NewRunningTracker(context.Background(), cmd)

	// start tracker
	ready, runErr := running.Start(testutils.TrackerDefaultStartupTimeout)
	require.NoError(t, runErr)

	r := <-ready // block until tracker is ready (or not)
	switch r {
	case testutils.TrackerFailed:
		t.Fatal("tracker failed to start")
	case testutils.TrackerTimedout:
		t.Fatal("tracker timedout to start")
	case testutils.TrackerAlreadyRunning:
		t.Fatal("tracker is already running")
	}

	// do the test
	metricsErr := checkIfMetricsExist(metrics)
	pprofErr := checkIfPprofExist()

	// check if all metrics exist
	require.NoError(t, metricsErr)
	require.NoError(t, pprofErr)

	cmdErrs := running.Stop() // stop tracker
	require.Empty(t, cmdErrs)
}
