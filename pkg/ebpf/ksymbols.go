package ebpf

import (
	"unsafe"

	"github.com/khulnasoft-lab/libbpfgo"
	"github.com/khulnasoft-lab/libbpfgo/helpers"

	"github.com/khulnasoft-lab/tracker/pkg/errfmt"
	"github.com/khulnasoft-lab/tracker/pkg/events"
)

var maxKsymNameLen = 64 // Most match the constant in the bpf code
var globalSymbolOwner = "system"

func LoadKallsymsValues(ksymsTable helpers.KernelSymbolTable, ksymbols []string) map[string]*helpers.KernelSymbol {
	kallsymsMap := make(map[string]*helpers.KernelSymbol)
	for _, name := range ksymbols {
		symbol, err := ksymsTable.GetSymbolByName(globalSymbolOwner, name)
		if err == nil {
			kallsymsMap[name] = symbol
		}
	}
	return kallsymsMap
}

func SendKsymbolsToMap(bpfKsymsMap *libbpfgo.BPFMap, ksymbols map[string]*helpers.KernelSymbol) error {
	for ksymName, value := range ksymbols {
		key := make([]byte, maxKsymNameLen)
		copy(key, ksymName)
		address := value.Address
		err := bpfKsymsMap.Update(unsafe.Pointer(&key[0]), unsafe.Pointer(&address))
		if err != nil {
			return errfmt.WrapError(err)
		}
	}
	return nil
}

func (t *Tracker) NewKernelSymbols() error {
	// reading kallsyms needs CAP_SYSLOG
	kernelSymbols, err := helpers.NewLazyKernelSymbolsMap()
	if err != nil {
		return errfmt.WrapError(err)
	}

	t.kernelSymbols = kernelSymbols

	return nil
}

func (t *Tracker) UpdateKernelSymbols() error {
	return t.kernelSymbols.Refresh()
}

func (t *Tracker) UpdateBPFKsymbolsMap() error {
	var err error
	var bpfKsymsMap *libbpfgo.BPFMap

	bpfKsymsMap, err = t.bpfModule.GetMap("ksymbols_map")
	if err != nil {
		return errfmt.WrapError(err)
	}

	// get required symbols by chosen events
	var reqKsyms []string

	for id := range t.eventsState {
		if !events.Core.IsDefined(id) {
			return errfmt.Errorf("wrong event id: %d", id)
		}
		eventDependencies := events.Core.GetDefinitionByID(id).GetDependencies()
		for _, symDependency := range eventDependencies.GetKSymbols() {
			reqKsyms = append(reqKsyms, symDependency.GetSymbol())
		}
	}
	kallsymsValues := LoadKallsymsValues(t.kernelSymbols, reqKsyms)

	return SendKsymbolsToMap(bpfKsymsMap, kallsymsValues)
}

func (t *Tracker) UpdateKallsyms() error {
	err := t.UpdateKernelSymbols()
	if err != nil {
		return errfmt.WrapError(err)
	}

	return t.UpdateBPFKsymbolsMap()
}
