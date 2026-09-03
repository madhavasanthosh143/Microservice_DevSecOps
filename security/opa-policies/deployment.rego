package main

# Conftest policy gating Kubernetes manifests before deploy.
# Run with: conftest test --policy security/opa-policies k8s/overlays/dev
# (after `kustomize build k8s/overlays/dev` renders the manifests).

deny[msg] {
	input.kind == "Deployment"
	container := input.spec.template.spec.containers[_]
	not container.resources.limits.cpu
	msg := sprintf("%s/%s: container %q has no CPU limit", [input.kind, input.metadata.name, container.name])
}

deny[msg] {
	input.kind == "Deployment"
	container := input.spec.template.spec.containers[_]
	not container.resources.limits.memory
	msg := sprintf("%s/%s: container %q has no memory limit", [input.kind, input.metadata.name, container.name])
}

deny[msg] {
	input.kind == "Deployment"
	container := input.spec.template.spec.containers[_]
	endswith(container.image, ":latest")
	msg := sprintf("%s/%s: container %q uses the mutable ':latest' tag", [input.kind, input.metadata.name, container.name])
}

deny[msg] {
	input.kind == "Deployment"
	not input.spec.template.spec.securityContext.runAsNonRoot == true
	msg := sprintf("%s/%s: pod does not set runAsNonRoot: true", [input.kind, input.metadata.name])
}

deny[msg] {
	input.kind == "Deployment"
	container := input.spec.template.spec.containers[_]
	container.securityContext.allowPrivilegeEscalation == true
	msg := sprintf("%s/%s: container %q allows privilege escalation", [input.kind, input.metadata.name, container.name])
}

deny[msg] {
	input.kind == "Deployment"
	container := input.spec.template.spec.containers[_]
	not container.securityContext.readOnlyRootFilesystem == true
	msg := sprintf("%s/%s: container %q does not use a read-only root filesystem", [input.kind, input.metadata.name, container.name])
}

deny[msg] {
	input.kind == "Deployment"
	container := input.spec.template.spec.containers[_]
	not container.livenessProbe
	msg := sprintf("%s/%s: container %q has no livenessProbe", [input.kind, input.metadata.name, container.name])
}
