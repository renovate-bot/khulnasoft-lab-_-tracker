# Cosign: verify tracker signature


## Prerequisites

Before you begin, ensure that you have the following:

- [cosign](https://docs.sigstore.dev/cosign/installation/)

## Verify tracker signature

Tracker images are signed with cosign keyless. To verify the signature we can run the command:

```console
cosign verify khulnasoft/tracker:{{ git.tag }}  --certificate-oidc-issuer https://token.actions.githubusercontent.com --certificate-identity-regexp https://github.com/khulnasoft-lab/tracker | jq
```
