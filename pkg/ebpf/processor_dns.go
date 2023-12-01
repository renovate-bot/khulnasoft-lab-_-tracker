package ebpf

import (
	"fmt"

	"github.com/khulnasoft-lab/tracker/pkg/events"
	"github.com/khulnasoft-lab/tracker/pkg/logger"
	"github.com/khulnasoft-lab/tracker/types/trace"
)

func (t *Tracker) populateDnsCache(event *trace.Event) error {
	if event.EventID != int(events.NetPacketDNS) {
		// Sanity check.
		return fmt.Errorf("received event %s: event is not net_packet_dns_response", event.EventName)
	}

	err := t.dnsCache.Add(event)
	if err != nil {
		logger.Errorw("error caching dns data from event", "error", err)
	}
	return nil
}
