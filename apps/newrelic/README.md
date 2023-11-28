# New Relic 
Requires exclusions for nri-metadata-injection pod:

```
nri-metadata-injection:
  podAnnotations:
    qpoint.io/egress: disabled
```
