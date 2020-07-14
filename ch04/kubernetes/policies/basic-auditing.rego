package kubernetes.admission

import data.kubernetes.pods

operations = {"CREATE", "UPDATE"}

deny[msg] {
    input.request.kind.kind == "Pod"
    operations[input.request.operation]
    containers := pod_containers(input.request.object)
    missing_resources(containers[_])
    msg := "The container doesn't under resource management"
}

pod_containers(pod) = cs {
	keys = {"containers", "initContainers"}
	cs = [c | keys[k]; c = pod.spec[k][_]]
}

missing_resources(container) {
	not container.resources.limits.cpu
}

missing_resources(container) {
	not container.resources.limits.memory
}

missing_resources(container) {
	not container.resources.requests.cpu
}

missing_resources(container) {
	not container.resources.requests.memory
}
