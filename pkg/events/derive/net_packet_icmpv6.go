package derive

import (
	"net"

	"github.com/google/gopacket"
	"github.com/google/gopacket/layers"

	"github.com/khulnasoft-lab/tracker/pkg/events"
	"github.com/khulnasoft-lab/tracker/types/trace"
)

func NetPacketICMPv6() DeriveFunction {
	return deriveSingleEvent(events.NetPacketICMPv6, deriveNetPacketICMPv6Args())
}

func deriveNetPacketICMPv6Args() deriveArgsFunction {
	return func(event trace.Event) ([]interface{}, error) {
		var srcIP net.IP
		var dstIP net.IP

		payload, err := parsePayloadArg(&event)
		if err != nil {
			return nil, err
		}

		// event retval encodes layer 3 protocol type

		if event.ReturnValue&familyIpv6 != familyIpv6 {
			return nil, nil
		}

		// parse packet

		packet := gopacket.NewPacket(
			payload,
			layers.LayerTypeIPv6,
			gopacket.Default,
		)
		if packet == nil {
			return []interface{}{}, parsePacketError()
		}

		layer3 := packet.NetworkLayer()

		switch v := layer3.(type) {
		case (*layers.IPv6):
			srcIP = v.SrcIP
			dstIP = v.DstIP
		default:
			return nil, nil
		}

		// some people says layer 4 (but icmp is a network layer in practice)

		layer4 := packet.Layer(layers.LayerTypeICMPv6)

		switch l4 := layer4.(type) {
		case (*layers.ICMPv6):
			var icmpv6 trace.ProtoICMPv6

			copyICMPv6ToProtoICMPv6(l4, &icmpv6)
			md := trace.PacketMetadata{
				Direction: getPacketDirection(&event),
			}

			// TODO: parse subsequent ICMPv6 type layers

			return []interface{}{
				srcIP,
				dstIP,
				md,
				icmpv6,
			}, nil
		}

		return nil, notProtoPacketError("ICMPv6")
	}
}

//
// ICMPv6 protocol type conversion (from gopacket layer to trace type)
//

func copyICMPv6ToProtoICMPv6(l4 *layers.ICMPv6, proto *trace.ProtoICMPv6) {
	proto.TypeCode = l4.TypeCode.String()
	proto.Checksum = l4.Checksum
}
