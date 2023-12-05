# New Relic

Requires exclusions for nri-metadata-injection pod:

```text
nri-metadata-injection:
  labels:
    qpoint.io/egress: disable
```