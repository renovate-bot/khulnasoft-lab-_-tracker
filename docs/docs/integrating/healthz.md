# Special: Healthz Endpoint

**tracker** supports a flag `--healthz` which enable a
`/healthz` endpoint that returns if `OK` if the process are healthy.

Example:

```console
tracker --healthz
curl http://localhost:3366/healthz
```

```text
OK
```

The port used is the default port `3366` for `tracker`.
It can be customized with the flag `--listen-addr`. 

Example:

```console
tracker --healthz --listen-addr=:8080
curl http://localhost:8080/healthz
```

```text
OK
```

