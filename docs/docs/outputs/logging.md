Configure log severity:

```console
sudo ./dist/tracker --log debug
```

Redirect logs to a file if needed:

```console
sudo ./dist/tracker --scope comm=bash --scope follow --events openat --output json:/tmp/tracker.events --log file:/tmp/tracker.log
```

Logs can be aggregated for a given interval to delay its output:

```console
sudo ./dist/tracker --log debug --log aggregate:5s
```

Filter logs which message contains specified words:

```console
sudo ./dist/tracker --log filter:msg=foo,bar
```

Filter logs using regular expressions against messages:

```console
sudo ./dist/tracker --log filter:regex='^foo'
```

Filter logs originating from a specific package:

```console
sudo ./dist/tracker --log filter:pkg=core
```

Filter logs originating from a specific file:

```console
sudo ./dist/tracker --log filter:file=/pkg/cmd/flags/logger.go
```

Filter logs based on their severity level:

```console
sudo ./dist/tracker --log filter:lvl=error
```

Filter logs originating from libbpf:

```console
sudo ./dist/tracker --log filter:libbpf
```

All `--log filter` options can also be used with `--log filter-out` for the opposite behavior. For more information, please refer to the `--log` help in the CLI.
