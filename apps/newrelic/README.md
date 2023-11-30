# New Relic

Requires exclusions for nri-metadata-injection pod:

```text
nri-metadata-injection:
  podAnnotations:
    qpoint.io/egress: disabled
```
