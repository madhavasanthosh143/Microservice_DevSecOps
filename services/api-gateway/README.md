# api-gateway

Placeholder — application source and a `Dockerfile` go here. The pipeline
in [.github/workflows/api-gateway.yml](../../.github/workflows/api-gateway.yml) expects:

- Buildable at this path with `mvn -B -f pom.xml verify` (override via the
  `build-command` input in the workflow if this isn't a Maven/Spring Boot
  service).
- A `Dockerfile` here that produces an image listening on port 8080
  and exposing `/actuator/health/readiness` and `/actuator/health/liveness`
  (or equivalent) for the Kubernetes probes defined in
  [k8s/base/api-gateway/deployment.yaml](../../k8s/base/api-gateway/deployment.yaml).
