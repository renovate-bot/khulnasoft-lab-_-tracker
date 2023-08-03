package main

# Returns the map of signature identifiers to signature metadata.
__rego_metadoc_all__[id] = resp {
	some i
		resp := data.tracker[i].__rego_metadoc__
		id := resp.id
}

# Returns the map of signature identifiers to signature selected events.
tracker_selected_events_all[id] = resp {
	some i
		resp := data.tracker[i].tracker_selected_events
		metadata := data.tracker[i].__rego_metadoc__
		id := metadata.id
}

# Returns the map of signature identifiers to values matching the input event.
tracker_match_all[id] = resp {
	some i
		resp := data.tracker[i].tracker_match
		metadata := data.tracker[i].__rego_metadoc__
		id := metadata.id
}