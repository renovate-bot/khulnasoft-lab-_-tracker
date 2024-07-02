.PHONY: all | env
all: tracker-ebpf tracker-rules signatures tracker

#
# make
#

.ONESHELL:
SHELL = /bin/sh

PARALLEL = $(shell $(CMD_GREP) -c ^processor /proc/cpuinfo)
MAKE = make
MAKEFLAGS += --no-print-directory

#
# tools
#

CMD_AWK ?= awk
CMD_CAT ?= cat
CMD_CLANG ?= clang
CMD_CUT ?= cut
CMD_ERRCHECK ?= errcheck
CMD_GIT ?= git
CMD_GO ?= go
CMD_GREP ?= grep
CMD_INSTALL ?= install
CMD_LLC ?= llc
CMD_MD5 ?= md5sum
CMD_MKDIR ?= mkdir
CMD_OPA ?= opa
CMD_PKGCONFIG ?= pkg-config
CMD_RM ?= rm
CMD_SED ?= sed
CMD_STATICCHECK ?= staticcheck
CMD_STRIP ?= llvm-strip
CMD_TOUCH ?= touch
CMD_TR ?= tr
CMD_PROTOC ?= protoc
CMD_PANDOC ?= pandoc
CMD_CONTROLLER_GEN ?= controller-gen

.check_%:
#
	@command -v $* >/dev/null
	if [ $$? -ne 0 ]; then
		echo "missing required tool $*"
		exit 1
	else
		touch $@ # avoid target rebuilds due to non-existing file
	fi

#
# libs
#

LIB_BPF ?= libbpf

# Recursively get private requirements of a library.
# It ignores libbpf as it is in 3rdparty, but considers its requirements.
fetch_priv_reqs_recursive = \
get_priv_reqs_recursive() { \
	lib=$$1; \
	processed_libs=$$2; \
	if echo "$$processed_libs" | grep -qw "$$lib"; then \
		return; \
	fi; \
	processed_libs="$$processed_libs $$lib"; \
	if [ "$$lib" = "libbpf" ]; then \
		priv_reqs=$$(PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(CMD_PKGCONFIG) --print-requires-private $$lib); \
	else \
		echo $$lib; \
		priv_reqs=$$($(CMD_PKGCONFIG) --print-requires-private $$lib); \
	fi; \
	for req in $$priv_reqs; do \
		if echo "$$processed_libs" | grep -qw "$$req"; then \
			continue; \
		fi; \
	done; \
	for req in $$priv_reqs; do \
		get_priv_reqs_recursive $$req "$$processed_libs"; \
	done; \
}; \
\
get_all_priv_reqs() { \
	lib=$$1; \
	get_priv_reqs_recursive $$lib ""; \
}; \
\
get_all_priv_reqs $$1

.checklib_%: \
	| .check_$(CMD_PKGCONFIG)
#
	@{ \
		$(eval required_libs := $(shell sh -c '$(fetch_priv_reqs_recursive) $*'))
		$(eval output := $(shell sh -c '\
		for lib in "$(required_libs)"; do \
			$(CMD_PKGCONFIG) --silence-errors --validate $$lib 2>/dev/null || echo "$$lib"; \
		done'))
		if [ -n "$(output)" ]; then \
			echo "missing required library: $(output)"; \
			exit 1; \
		fi; \
	} && touch $@ # avoid target rebuilds due to non-existing file

#
# tools version
#

CLANG_VERSION = $(shell $(CMD_CLANG) --version 2>/dev/null | \
	head -1 | $(CMD_TR) -d '[:alpha:]' | $(CMD_TR) -d '[:space:]' | $(CMD_CUT) -d'.' -f1)

.checkver_$(CMD_CLANG): \
	| .check_$(CMD_CLANG)
#
	@if [ ${CLANG_VERSION} -lt 12 ]; then
		echo -n "you MUST use clang 12 or newer, "
		echo "your current clang version is ${CLANG_VERSION}"
		exit 1
	fi
	touch $@ # avoid target rebuilds over and over due to non-existing file

GO_VERSION = $(shell $(CMD_GO) version 2>/dev/null | $(CMD_AWK) '{print $$3}' | $(CMD_SED) 's:go::g' | $(CMD_CUT) -d. -f1,2)
GO_VERSION_MAJ = $(shell echo $(GO_VERSION) | $(CMD_CUT) -d'.' -f1)
GO_VERSION_MIN = $(shell echo $(GO_VERSION) | $(CMD_CUT) -d'.' -f2)

.checkver_$(CMD_GO): \
	| .check_$(CMD_GO)
#
	@if [ ${GO_VERSION_MAJ} -eq 1 ]; then
		if [ ${GO_VERSION_MIN} -lt 18 ]; then
			echo -n "you MUST use golang 1.18 or newer, "
			echo "your current golang version is ${GO_VERSION}"
			exit 1
		fi
	fi
	touch $@

#
# version
#

LAST_GIT_TAG ?= $(shell $(CMD_GIT) describe --tags --match 'v*' 2>/dev/null)
VERSION ?= $(if $(RELEASE_TAG),$(RELEASE_TAG),$(LAST_GIT_TAG))

#
# environment
#

DEBUG ?= 0
UNAME_M := $(shell uname -m)
UNAME_R := $(shell uname -r)

ifeq ($(DEBUG),1)
	GO_DEBUG_FLAG =
else
	GO_DEBUG_FLAG = -w
endif

ifeq ($(UNAME_M),x86_64)
	ARCH = x86_64
	LINUX_ARCH = x86
	GO_ARCH = amd64
endif

ifeq ($(UNAME_M),aarch64)
	ARCH = arm64
	LINUX_ARCH = arm64
	GO_ARCH = arm64
endif

.PHONY: env
env:
	@echo ---------------------------------------
	@echo "Makefile Environment:"
	@echo ---------------------------------------
	@echo "PARALLEL                 $(PARALLEL)"
	@echo ---------------------------------------
	@echo "CLANG_VERSION            $(CLANG_VERSION)"
	@echo "GO_VERSION               $(GO_VERSION)"
	@echo ---------------------------------------
	@echo "CMD_AWK                  $(CMD_AWK)"
	@echo "CMD_CAT                  $(CMD_CAT)"
	@echo "CMD_CLANG                $(CMD_CLANG)"
	@echo "CMD_CUT                  $(CMD_CUT)"
	@echo "CMD_ERRCHECK             $(CMD_ERRCHECK)"
	@echo "CMD_GIT                  $(CMD_GIT)"
	@echo "CMD_GO                   $(CMD_GO)"
	@echo "CMD_GREP                 $(CMD_GREP)"
	@echo "CMD_INSTALL              $(CMD_INSTALL)"
	@echo "CMD_LLC                  $(CMD_LLC)"
	@echo "CMD_MD5                  $(CMD_MD5)"
	@echo "CMD_MKDIR                $(CMD_MKDIR)"
	@echo "CMD_OPA                  $(CMD_OPA)"
	@echo "CMD_PKGCONFIG            $(CMD_PKGCONFIG)"
	@echo "CMD_RM                   $(CMD_RM)"
	@echo "CMD_SED                  $(CMD_SED)"
	@echo "CMD_STATICCHECK          $(CMD_STATICCHECK)"
	@echo "CMD_STRIP                $(CMD_STRIP)"
	@echo "CMD_TOUCH                $(CMD_TOUCH)"
	@echo "CMD_TR                   $(CMD_TR)"
	@echo "CMD_PROTOC               $(CMD_PROTOC)"
	@echo ---------------------------------------
	@echo "LIB_BPF                  $(LIB_BPF)"
	@echo ---------------------------------------
	@echo "VERSION                  $(VERSION)"
	@echo "LAST_GIT_TAG             $(LAST_GIT_TAG)"
	@echo ---------------------------------------
	@echo "UNAME_M                  $(UNAME_M)"
	@echo "UNAME_R                  $(UNAME_R)"
	@echo "ARCH                     $(ARCH)"
	@echo "LINUX_ARCH               $(LINUX_ARCH)"
	@echo ---------------------------------------
	@echo "OUTPUT_DIR               $(OUTPUT_DIR)"
	@echo ---------------------------------------
	@echo "LIBBPF_CFLAGS            $(LIBBPF_CFLAGS)"
	@echo "LIBBPF_LDLAGS            $(LIBBPF_LDFLAGS)"
	@echo "LIBBPF_SRC               $(LIBBPF_SRC)"
	@echo ---------------------------------------
	@echo "STATIC                   $(STATIC)"
	@echo ---------------------------------------
	@echo "BPF_VCPU                 $(BPF_VCPU)"
	@echo "TRACKER_EBPF_OBJ_SRC      $(TRACKER_EBPF_OBJ_SRC)"
	@echo "TRACKER_EBPF_OBJ_HEADERS  $(TRACKER_EBPF_OBJ_HEADERS)"
	@echo ---------------------------------------
	@echo "GO_ARCH                  $(GO_ARCH)"
	@echo "GO_TAGS_EBPF             $(GO_TAGS_EBPF)"
	@echo "GO_TAGS_RULES            $(GO_TAGS_RULES)"
	@echo ---------------------------------------
	@echo "DEBUG                    $(DEBUG)"
	@echo "GO_DEBUG_FLAG            $(GO_DEBUG_FLAG)"
	@echo ---------------------------------------
	@echo "CUSTOM_CGO_CFLAGS        $(CUSTOM_CGO_CFLAGS)"
	@echo "CUSTOM_CGO_LDFLAGS       $(CUSTOM_CGO_LDFLAGS)"
	@echo "CGO_EXT_LDFLAGS_EBPF     $(CGO_EXT_LDFLAGS_EBPF)"
	@echo "CGO_EXT_LDFLAGS_RULES    $(CGO_EXT_LDFLAGS_RULES)"
	@echo ---------------------------------------
	@echo "GO_ENV_EBPF              $(GO_ENV_EBPF)"
	@echo "GO_ENV_RULES             $(GO_ENV_RULES)"
	@echo ---------------------------------------
	@echo "TRACKER_SRC               $(TRACKER_SRC)"
	@echo "TRACKER_SRC_DIRS          $(TRACKER_SRC_DIRS)"
	@echo ---------------------------------------
	@echo "TRACKER_RULES_SRC_DIRS    $(TRACKER_RULES_SRC_DIRS)"
	@echo "TRACKER_RULES_SRC         $(TRACKER_RULES_SRC)"
	@echo ---------------------------------------
	@echo "TRACKER_BENCH_SRC_DIRS    $(TRACKER_BENCH_SRC_DIRS)"
	@echo "TRACKER_BENCH_SRC         $(TRACKER_BENCH_SRC)"
	@echo ---------------------------------------
	@echo "TRACKER_GPTDOCS_SRC_DIRS  $(TRACKER_GPTDOCS_SRC_DIRS)"
	@echo "TRACKER_GPTDOCS_SRC       $(TRACKER_GPTDOCS_SRC)"
	@echo ---------------------------------------
	@echo "GOSIGNATURES_DIR         $(GOSIGNATURES_DIR)"
	@echo "GOSIGNATURES_SRC         $(GOSIGNATURES_SRC)"
	@echo ---------------------------------------
	@echo "REGO_SIGNATURES_DIR      $(REGO_SIGNATURES_DIR)"
	@echo "REGO_SIGNATURES_SRC      $(REGO_SIGNATURES_SRC)"
	@echo ---------------------------------------
	@echo "E2E_NET_DIR              $(E2E_NET_DIR)"
	@echo "E2E_NET_SRC              $(E2E_NET_SRC)"
	@echo "E2E_INST_DIR             $(E2E_INST_DIR)"
	@echo "E2E_INST_SRC             $(E2E_INST_SRC)"
	@echo ---------------------------------------
	@echo "TRACKER_PROTOS            $(TRACKER_PROTOS)"
	@echo ---------------------------------------

#
# usage
#

.PHONY: help
help:
	@echo ""
	@echo "# environment"
	@echo ""
	@echo "    $$ make env                      # show makefile environment/variables"
	@echo ""
	@echo "# build"
	@echo ""
	@echo "    $$ make all                      # build tracker-ebpf, tracker-rules & signatures"
	@echo "    $$ make bpf                      # build ./dist/tracker.bpf.o"
	@echo "    $$ make tracker-ebpf              # build ./dist/tracker-ebpf"
	@echo "    $$ make tracker-rules             # build ./dist/tracker-rules"
	@echo "    $$ make tracker-bench             # build ./dist/tracker-bench"
	@echo "    $$ make tracker-gptdocs           # build ./dist/tracker-gptdocs"
	@echo "    $$ make signatures               # build ./dist/signatures"
	@echo "    $$ make e2e-net-signatures       # build ./dist/e2e-net-signatures"
	@echo "    $$ make e2e-inst-signatures      # build ./dist/e2e-inst-signatures"
	@echo "    $$ make tracker                   # build ./dist/tracker"
	@echo "    $$ make tracker-operator          # build ./dist/tracker-operator"
	@echo ""
	@echo "# clean"
	@echo ""
	@echo "    $$ make clean                    # wipe ./dist/"
	@echo "    $$ make clean-bpf                # wipe ./dist/tracker.bpf.o"
	@echo "    $$ make clean-tracker-ebpf        # wipe ./dist/tracker-ebpf"
	@echo "    $$ make clean-tracker-rules       # wipe ./dist/tracker-rules"
	@echo "    $$ make clean-tracker-bench       # wipe ./dist/tracker-bench"
	@echo "    $$ make clean-signatures         # wipe ./dist/signatures"
	@echo "    $$ make clean-tracker             # wipe ./dist/tracker"
	@echo "    $$ make clean-tracker-operator    # wipe ./dist/tracker-operator"
	@echo ""
	@echo "# test"
	@echo ""
	@echo "    $$ make test-unit                # run unit tests"
	@echo "    $$ make test-types               # run unit tests for types module"
	@echo "    $$ make test-integration         # run integration tests"
	@echo "    $$ make test-signatures          # opa test (tracker-rules)"
	@echo ""
	@echo "# flags"
	@echo ""
	@echo "    $$ STATIC=1 make ...             # build static binaries"
	@echo "    $$ BTFHUB=1 STATIC=1 make ...    # build static binaries, embed BTF"
	@echo "    $$ DEBUG=1 make ...              # build binaries with debug symbols"
	@echo ""

#
# variables
#

BPF_VCPU = v2

#
# output dir
#

OUTPUT_DIR = ./dist

$(OUTPUT_DIR):
#
	@$(CMD_MKDIR) -p $@
	$(CMD_MKDIR) -p $@/libbpf
	$(CMD_MKDIR) -p $@/libbpf/obj

#
# embedded btfhub
#

$(OUTPUT_DIR)/btfhub:
#
	@$(CMD_MKDIR) -p $@
	$(CMD_TOUCH) $@/.place-holder

#
# libbpf (statically linked)
#

LIBBPF_CFLAGS = "-fPIC"
LIBBPF_LDFLAGS =
LIBBPF_SRC = ./3rdparty/libbpf/src
LIBBPF_DESTDIR = $(OUTPUT_DIR)/libbpf
LIBBPF_OBJDIR = $(LIBBPF_DESTDIR)/obj
LIBBPF_OBJ = $(LIBBPF_OBJDIR)/libbpf.a

$(LIBBPF_OBJ): \
	$(LIBBPF_SRC) \
	$(wildcard $(LIBBPF_SRC)/*.[ch]) \
	| .checkver_$(CMD_CLANG) $(OUTPUT_DIR)
#
	CC="$(CMD_CLANG)" \
		CFLAGS="$(LIBBPF_CFLAGS)" \
		LD_FLAGS="$(LIBBPF_LDFLAGS)" \
		$(MAKE) \
		-C $(LIBBPF_SRC) \
		BUILD_STATIC_ONLY=1 \
		DESTDIR=$(abspath $(LIBBPF_DESTDIR)) \
		OBJDIR=$(abspath $(LIBBPF_OBJDIR)) \
		LIBDIR=$(abspath $(LIBBPF_OBJDIR)) \
		INCLUDEDIR= UAPIDIR= prefix= libdir= \
		install install_uapi_headers

$(LIBBPF_SRC): \
	| .check_$(CMD_GIT)
#
ifeq ($(wildcard $@), )
	@$(CMD_GIT) submodule update --init --recursive
endif

#
# ebpf object
#

TRACKER_EBPF_OBJ_SRC = ./pkg/ebpf/c/tracker.bpf.c
TRACKER_EBPF_OBJ_HEADERS = $(shell find pkg/ebpf/c -name *.h)

.PHONY: bpf
bpf: $(OUTPUT_DIR)/tracker.bpf.o

$(OUTPUT_DIR)/tracker.bpf.o: \
	$(LIBBPF_OBJ) \
	$(TRACKER_EBPF_OBJ_SRC) \
	$(TRACKER_EBPF_OBJ_HEADERS)
#
	$(CMD_CLANG) \
		-D__TARGET_ARCH_$(LINUX_ARCH) \
		-D__BPF_TRACING__ \
		-DCORE \
		-I./pkg/ebpf/c/ \
		-I$(OUTPUT_DIR)/libbpf/ \
		-I ./3rdparty/include \
		-target bpf \
		-O2 -g \
		-mcpu=$(BPF_VCPU) \
		-c $(TRACKER_EBPF_OBJ_SRC) \
		-o $@

.PHONY: clean-bpf
clean-bpf:
#
	$(CMD_RM) -rf $(OUTPUT_DIR)/tracker.bpf.o

#
# common variables
#

STATIC ?= 0
TRACKER_SRC_DIRS = ./cmd/ ./pkg/ ./signatures/
TRACKER_SRC = $(shell find $(TRACKER_SRC_DIRS) -type f -name '*.go' ! -name '*_test.go')
GO_TAGS_EBPF = core,ebpf
CGO_EXT_LDFLAGS_EBPF =
CUSTOM_CGO_CFLAGS = "-I$(abspath $(OUTPUT_DIR)/libbpf)"
PKG_CONFIG_PATH = $(LIBBPF_OBJDIR)
PKG_CONFIG_FLAG =

ifeq ($(STATIC), 1)
    GO_TAGS_EBPF := $(GO_TAGS_EBPF),netgo
    CGO_EXT_LDFLAGS_EBPF += -static
    PKG_CONFIG_FLAG = --static
endif

CUSTOM_CGO_LDFLAGS = "$(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(CMD_PKGCONFIG) $(PKG_CONFIG_FLAG) --libs $(LIB_BPF))"
GO_ENV_EBPF =
GO_ENV_EBPF += GOOS=linux
GO_ENV_EBPF += CC=$(CMD_CLANG)
GO_ENV_EBPF += GOARCH=$(GO_ARCH)
GO_ENV_EBPF += CGO_CFLAGS=$(CUSTOM_CGO_CFLAGS)
GO_ENV_EBPF += CGO_LDFLAGS=$(CUSTOM_CGO_LDFLAGS)

TRACKER_PROTOS = ./api/v1beta1/*.proto

#
# btfhub (expensive: only run if ebpf obj changed)
#

SH_BTFHUB = ./3rdparty/btfhub.sh

.PHONY: btfhub
btfhub: \
	$(OUTPUT_DIR)/tracker.bpf.o \
	| .check_$(CMD_MD5)
#
ifeq ($(BTFHUB), 1)
	@new=$($(CMD_MD5) -b $< | cut -d' ' -f1)
	@if [ -f ".$(notdir $<).md5" ]; then
		old=$($(CMD_CAT) .$(notdir $<).md5)
		if [ "$$old" != "$$new" ]; then
			$(SH_BTFHUB) && echo $$new > .$(notdir $<).md5
		fi
	else
		$(SH_BTFHUB) && echo $$new > .$(notdir $<).md5
	fi
endif

#
# tracker (single binary)
#

.PHONY: tracker
tracker: $(OUTPUT_DIR)/tracker

$(OUTPUT_DIR)/tracker: \
	$(OUTPUT_DIR)/tracker.bpf.o \
	$(TRACKER_SRC) \
	| .checkver_$(CMD_GO) \
	.checklib_$(LIB_BPF) \
	btfhub \
	signatures
#
	$(MAKE) $(OUTPUT_DIR)/btfhub
	$(MAKE) btfhub
	$(GO_ENV_EBPF) $(CMD_GO) build \
		-tags $(GO_TAGS_EBPF) \
		-ldflags="$(GO_DEBUG_FLAG) \
			-extldflags \"$(CGO_EXT_LDFLAGS_EBPF)\" \
			-X github.com/khulnasoft-lab/tracker/pkg/version.version=$(VERSION) \
			" \
		-v -o $@ \
		./cmd/tracker

.PHONY: clean-tracker
clean-tracker:
#
	$(CMD_RM) -rf $(OUTPUT_DIR)/tracker
	$(CMD_RM) -rf .*.md5

#
# tracker-ebpf (deprecated)
#

.PHONY: tracker-ebpf
tracker-ebpf: $(OUTPUT_DIR)/tracker-ebpf

$(OUTPUT_DIR)/tracker-ebpf: \
	$(OUTPUT_DIR)/tracker.bpf.o \
	$(TRACKER_SRC) \
	| .checkver_$(CMD_GO) \
	.checklib_$(LIB_BPF) \
	btfhub
#
	$(MAKE) $(OUTPUT_DIR)/btfhub
	$(MAKE) btfhub
	$(GO_ENV_EBPF) $(CMD_GO) build \
		-tags $(GO_TAGS_EBPF) \
		-ldflags="$(GO_DEBUG_FLAG) \
			-extldflags \"$(CGO_EXT_LDFLAGS_EBPF)\" \
			-X main.version=\"$(VERSION)\" \
			" \
		-v -o $@ \
		./cmd/tracker-ebpf

.PHONY: clean-tracker-ebpf
clean-tracker-ebpf:
#
	$(CMD_RM) -rf $(OUTPUT_DIR)/tracker-ebpf
	$(CMD_RM) -rf .*.md5

#
# tracker-rules (deprecated)
#

STATIC ?= 0
GO_TAGS_RULES =
CGO_EXT_LDFLAGS_RULES =

ifeq ($(STATIC), 1)
    CGO_EXT_LDFLAGS_RULES += -static
    GO_TAGS_RULES := netgo
endif

GO_ENV_RULES =
GO_ENV_RULES += GOOS=linux
GO_ENV_RULES += CC=$(CMD_CLANG)
GO_ENV_RULES += GOARCH=$(GO_ARCH)
GO_ENV_RULES += CGO_CFLAGS=
GO_ENV_RULES += CGO_LDFLAGS=

TRACKER_RULES_SRC_DIRS = ./cmd/tracker-rules/ ./pkg/signatures/
TRACKER_RULES_SRC=$(shell find $(TRACKER_RULES_SRC_DIRS) -type f -name '*.go')

.PHONY: tracker-rules
tracker-rules: $(OUTPUT_DIR)/tracker-rules

$(OUTPUT_DIR)/tracker-rules: \
	$(TRACKER_RULES_SRC) \
	| .checkver_$(CMD_GO) \
	$(OUTPUT_DIR) \
	signatures
#
	$(GO_ENV_RULES) $(CMD_GO) build \
		-tags $(GO_TAGS_RULES) \
		-ldflags="$(GO_DEBUG_FLAG) \
			-extldflags \"$(CGO_EXT_LDFLAGS_RULES)\" \
			" \
		-v -o $@ \
		./cmd/tracker-rules

.PHONY: clean-tracker-rules
clean-tracker-rules:
#
	$(CMD_RM) -rf $(OUTPUT_DIR)/tracker-rules

#
# signatures
#

GOSIGNATURES_DIR ?= signatures/golang
GOSIGNATURES_SRC :=	$(shell find $(GOSIGNATURES_DIR) \
			-type f \
			-name '*.go' \
			! -name '*_test.go' \
			! -path '$(GOSIGNATURES_DIR)/examples/*' \
			)

REGO_SIGNATURES_DIR ?= signatures/rego
REGO_SIGNATURES_SRC :=	$(shell find $(REGO_SIGNATURES_DIR) \
			-type f \
			-name '*.rego' \
			! -name '*_test.rego' \
			! -path '$(REGO_SIGNATURES_DIR)/examples/*' \
			)

.PHONY: signatures
signatures: $(OUTPUT_DIR)/signatures

$(OUTPUT_DIR)/signatures: \
	$(GOSIGNATURES_SRC) \
	$(REGO_SIGNATURES_SRC) \
	| .checkver_$(CMD_GO) \
	.check_$(CMD_INSTALL) \
	$(OUTPUT_DIR)
#
	$(CMD_MKDIR) -p $@
	$(GO_ENV_RULES) $(CMD_GO) build \
		--buildmode=plugin \
		-o $@/builtin.so \
		$(GOSIGNATURES_SRC)
	# disable rego signatures by default (keep golang signatures only)
	# $(CMD_INSTALL) -m 0644 $(REGO_SIGNATURES_SRC) $@

.PHONY: clean-signatures
clean-signatures:
#
	$(CMD_RM) -rf $(OUTPUT_DIR)/signatures

#
# other commands
#

# tracker-bench

TRACKER_BENCH_SRC_DIRS = ./cmd/tracker-bench/
TRACKER_BENCH_SRC = $(shell find $(TRACKER_BENCH_SRC_DIRS) \
			-type f \
			-name '*.go' \
			! -name '*_test.go' \
			)

.PHONY: tracker-bench
tracker-bench: $(OUTPUT_DIR)/tracker-bench

$(OUTPUT_DIR)/tracker-bench: \
	$(TRACKER_BENCH_SRC) \
	| .checkver_$(CMD_GO) \
	$(OUTPUT_DIR)
#
	$(CMD_GO) build \
		-v -o $@ \
		./cmd/tracker-bench

.PHONY: clean-tracker-bench
clean-tracker-bench:
#
	$(CMD_RM) -rf $(OUTPUT_DIR)/tracker-bench

# tracker-gptdocs

TRACKER_GPTDOCS_SRC_DIRS = ./cmd/tracker-gptdocs/ ./pkg/cmd/
TRACKER_GPTDOCS_SRC = $(shell find $(TRACKER_GPTDOCS_SRC_DIRS) \
			-type f \
			-name '*.go' \
			! -name '*_test.go' \
			)

.PHONY: tracker-gptdocs
tracker-gptdocs: $(OUTPUT_DIR)/tracker-gptdocs

$(OUTPUT_DIR)/tracker-gptdocs: \
	$(TRACKER_GPTDOCS_SRC) \
	$(LIBBPF_OBJ) \
	| .checkver_$(CMD_GO) \
	$(OUTPUT_DIR)
#
	$(MAKE) $(OUTPUT_DIR)/btfhub
	$(MAKE) btfhub
	$(GO_ENV_EBPF) $(CMD_GO) build \
		-tags $(GO_TAGS_EBPF) \
		-ldflags="$(GO_DEBUG_FLAG) \
			-extldflags \"$(CGO_EXT_LDFLAGS_EBPF)\" \
			-X main.version=\"$(VERSION)\" \
			" \
		-v -o $@ \
		./cmd/tracker-gptdocs

.PHONY: clean-tracker-gptdocs
clean-tracker-gptdocs:
#
	$(CMD_RM) -rf $(OUTPUT_DIR)/tracker-gptdocs

#
# functional tests (using test signatures)
#

# e2e network signatures

E2E_NET_DIR ?= tests/e2e-net-signatures
E2E_NET_SRC := $(shell find $(E2E_NET_DIR) \
		-type f \
		-name '*.go' \
		! -name '*_test.go' \
		)

.PHONY: e2e-net-signatures
e2e-net-signatures: $(OUTPUT_DIR)/e2e-net-signatures

$(OUTPUT_DIR)/e2e-net-signatures: \
	$(E2E_NET_SRC) \
	| .checkver_$(CMD_GO) \
	.check_$(CMD_INSTALL) \
	$(OUTPUT_DIR)
#
	$(CMD_MKDIR) -p $@
	$(GO_ENV_RULES) $(CMD_GO) build \
		--buildmode=plugin \
		-o $@/builtin.so \
		$(E2E_NET_SRC)

.PHONY: clean-e2e-net-signatures
clean-e2e-net-signatures:
#
	$(CMD_RM) -rf $(OUTPUT_DIR)/e2e-net-signatures

# e2e instrumentation signatures

E2E_INST_DIR ?= tests/e2e-inst-signatures
E2E_INST_SRC := $(shell find $(E2E_INST_DIR) \
		-type f \
		-name '*.go' \
		! -name '*_test.go' \
		! -path '$(E2E_INST_DIR)/scripts/*' \
		! -path '$(E2E_INST_DIR)/datasourcetest/*' \
		)

.PHONY: e2e-inst-signatures
e2e-inst-signatures: $(OUTPUT_DIR)/e2e-inst-signatures

$(OUTPUT_DIR)/e2e-inst-signatures: \
	$(E2E_INST_SRC) \
	| .checkver_$(CMD_GO) \
	.check_$(CMD_INSTALL) \
	$(OUTPUT_DIR)
#
	$(CMD_MKDIR) -p $@
	$(GO_ENV_RULES) $(CMD_GO) build \
		--buildmode=plugin \
		-o $@/builtin.so \
		$(E2E_INST_SRC)

.PHONY: clean-e2e-inst-signatures
clean-e2e-inst-signatures:
#
	$(CMD_RM) -rf $(OUTPUT_DIR)/e2e-inst-signatures

#
# unit tests
#

.PHONY: test-unit
test-unit: \
	tracker-ebpf \
	test-types \
	| .checkver_$(CMD_GO)
#
	@$(GO_ENV_EBPF) \
	$(CMD_GO) test \
		-tags ebpf \
		-short \
		-race \
		-shuffle on \
		-v \
		-coverprofile=coverage.txt \
		./cmd/... \
		./pkg/... \
		./signatures/... \

.PHONY: test-types
test-types: \
	| .checkver_$(CMD_GO)
#
	# Note that we must changed the directory here because types is a standalone Go module.
	@cd ./types && $(CMD_GO) test \
		-short \
		-race \
		-shuffle on \
		-v \
		-coverprofile=coverage.txt \
		./...

#
# integration tests
#

.PHONY: $(OUTPUT_DIR)/syscaller
$(OUTPUT_DIR)/syscaller: \
	$(LIBBPF_OBJ) \
	| .check_$(CMD_GO)
#
	$(GO_ENV_EBPF) \
	$(CMD_GO) build -o $(OUTPUT_DIR)/syscaller ./tests/integration/syscaller/cmd

.PHONY: test-integration
test-integration: \
	$(OUTPUT_DIR)/syscaller \
	tracker \
	| .checkver_$(CMD_GO)
#
	@$(GO_ENV_EBPF) \
	$(CMD_GO) test \
		-tags $(GO_TAGS_EBPF) \
		-ldflags="$(GO_DEBUG_FLAG) \
			-extldflags \"$(CGO_EXT_LDFLAGS_EBPF)\" \
			-X main.version=\"$(VERSION)\" \
			" \
		-shuffle on \
		-race \
		-v \
		-p 1 \
		-count=1 \
		./tests/integration/... \

.PHONY: test-signatures
test-signatures: \
	| .check_$(CMD_OPA)
#
	$(CMD_OPA) test $(REGO_SIGNATURES_DIR) --verbose

.PHONY: test-upstream-libbpfgo
test-upstream-libbpfgo: \
	| .checkver_$(CMD_GO)
#
	./tests/libbpfgo.sh $(GO_ENV_EBPF)

#
# performance tests
#

.PHONY: test-performance
test-performance: \
	tracker \
	| .checkver_$(CMD_GO)
#
	@$(GO_ENV_EBPF) \
	$(CMD_GO) test \
		-tags $(GO_TAGS_EBPF) \
		-ldflags="$(GO_DEBUG_FLAG) \
			-extldflags \"$(CGO_EXT_LDFLAGS_EBPF)\" \
			-X main.version=\"$(VERSION)\" \
			" \
		-race \
		-shuffle on \
		-v \
		-p 1 \
		-count=1 \
		./tests/perftests/... \

#
# code checkers (hidden from help on purpose)
#

.PHONY: check-fmt
check-fmt::
#
	@$(MAKE) -f builder/Makefile.checkers fmt-check

.PHONY: fix-fmt
fix-fmt::
#
	@$(MAKE) -f builder/Makefile.checkers fmt-fix

.PHONY: check-lint
check-lint::
#
	@$(MAKE) -f builder/Makefile.checkers lint-check

.PHONY: check-code
check-code:: \
	tracker-ebpf
#
	@$(MAKE) -f builder/Makefile.checkers code-check


.PHONY: check-vet
check-vet: \
	tracker-ebpf \
	| .checkver_$(CMD_GO)
#
	@$(GO_ENV_EBPF) \
	$(CMD_GO) vet \
		-tags $(GO_TAGS_EBPF) \
		./...

.PHONY: check-staticcheck
check-staticcheck: \
	tracker-ebpf \
	| .checkver_$(CMD_GO) \
	.check_$(CMD_STATICCHECK)
#
	@$(GO_ENV_EBPF) \
	$(CMD_STATICCHECK) -f stylish \
		-tags $(GO_TAGS_EBPF) \
		./...

.PHONY: check-err
check-err: \
	tracker-ebpf \
	| .checkver_$(CMD_GO) \
	.check_$(CMD_ERRCHECK)
#
	@$(CMD_ERRCHECK) \
		-tags $(GO_TAGS_EBPF) \
		-ignoretests \
		-ignore 'fmt:[FS]?[Pp]rint*|[wW]rite' \
		-ignore '[rR]ead|[wW]rite' \
		-ignore 'RegisterEventProcessor' \
		./...

#
# pull request verifier
#

LOGFROM ?= main

.PHONY: format-pr
format-pr: \
	| .check_$(CMD_GIT)
#
	@echo
	@echo "👇 PR Comment BEGIN"
	@echo

	@$(CMD_GIT) \
		log $(LOGFROM)..HEAD \
		--pretty=format:'%C(auto,yellow)%h%Creset **%C(auto,red)%s%Creset**'

	@echo
	@echo

	@output=$$($(CMD_GIT) rev-list $(LOGFROM)..HEAD | while read commit; do \
		body="$$($(CMD_GIT) show --no-patch --format=%b $$commit | sed ':a;N;$$!ba;s/\n$$//')"; \
		if [ -n "$$body" ]; then \
			$(CMD_GIT) \
				show -s $$commit \
				--color=always \
				--format='%C(auto,yellow)%h%Creset **%C(auto,red)%s%Creset**%n'; \
			echo '```'; \
			echo "$$body"; \
			echo '```'; \
			echo; \
		fi; \
	done); \
	echo "$$output"

	@echo
	@echo "👆 PR Comment END"
	@echo

.PHONY: check-pr
check-pr: \
	check-fmt \
	check-lint \
	check-code \
	format-pr

#
# tracker.proto
#

.PHONY: protoc
protoc:
#
	$(CMD_PROTOC) \
		--go_out=. \
		--go_opt=paths=source_relative \
		--go-json_out=orig_name=true,paths=source_relative:. \
		--go-grpc_out=. \
		--go-grpc_opt=paths=source_relative $(TRACKER_PROTOS)

#
# man pages
#

MARKDOWN_DIR ?= ./docs/docs/flags
MAN_DIR ?= ./docs/man
MARKDOW_FILES := $(shell find $(MARKDOWN_DIR) \
					-type f \
					-name '*.md' \
				)
MAN_FILES := $(patsubst $(MARKDOWN_DIR)/%.md,$(MAN_DIR)/%,$(MARKDOW_FILES))

$(MAN_DIR)/%: $(MARKDOWN_DIR)/%.md \
	| .check_$(CMD_PANDOC) \
#
	@echo Generating $@
	@$(CMD_PANDOC) \
		--verbose \
		--standalone \
		--to man \
		$< \
		-o $@

.PHONY: clean-man
clean-man:
	@echo Cleaning $(MAN_DIR)
	@rm -f $(MAN_DIR)/*

.PHONY: man
man: clean-man $(MAN_FILES)


#
# clean
#

.PHONY: clean
clean:
#
	$(CMD_RM) -rf $(OUTPUT_DIR)
	$(CMD_RM) -f .*.md5
	$(CMD_RM) -f .check*
	$(CMD_RM) -f .*-pkgs*

# tracker-operator

.PHONY: tracker-operator
tracker-operator: $(OUTPUT_DIR)/tracker-operator

$(OUTPUT_DIR)/tracker-operator: \
	| .checkver_$(CMD_GO) \
	$(OUTPUT_DIR)
#
	$(CMD_GO) build \
		-v -o $@ \
		./cmd/tracker-operator

.PHONY: clean-tracker-operator
clean-tracker-operator:
#
	$(CMD_RM) -rf $(OUTPUT_DIR)/tracker-operator

# kubernetes operator

.PHONY: k8s-manifests
k8s-manifests: ## Generate WebhookConfiguration, ClusterRole and CustomResourceDefinition objects.
	$(CMD_CONTROLLER_GEN) rbac:roleName=tracker crd webhook paths="./pkg/k8s/..." output:crd:artifacts:config=deploy/helm/tracker/crds output:rbac:artifacts:config=deploy/helm/tracker/templates/

.PHONY: k8s-generate
k8s-generate: ## Generate code containing DeepCopy, DeepCopyInto, and DeepCopyObject method implementations.
	$(CMD_CONTROLLER_GEN) object:headerFile="deploy/boilerplate.go.txt" paths="./pkg/k8s/..."

# benchmarks
.PHONY: bench-network
bench-network:
	./performance/benchmark/network/bench.sh $(IMAGE) $(OUTPUT) $(TIME)