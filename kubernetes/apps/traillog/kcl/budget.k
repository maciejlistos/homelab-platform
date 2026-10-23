# NamespaceBudget describes aggregate namespace ceilings.
# CPU is modeled in millicores and memory in MiB to make check numeric.
schema NamespaceBudget:
    request_cpu_milli: int = 1000
    limit_cpu_milli: int = 2000
    request_memory_mib: int = 512
    limit_memory_mib: int = 1024
    storage_gib: int = 16

    check:
        request_cpu_milli > 0, "CPU request budget must be positive"
        limit_cpu_milli >= request_cpu_milli, "CPU limit budget must cover request budget"
        request_memory_mib > 0, "Memory request budget must be positive"
        limit_memory_mib >= request_memory_mib, "Memory limit budet must cover request budeget"
        storage_gib >= 12, "Budget must accommodate the inital 2GiB data plus 10 GiB backup claim"

_budget = NamespaceBudget {}

apiVersion = "v1"
kind = "ResourceQuota"
metadata = {
    name = "traillog-budget"
    namespace = "traillog"
}
spec = {
    hard = {
        "requests.cpu" = "${_budget.request_cpu_milli}m"
        "limits.cpu" = "${_budget.limit_cpu_milli}m"
        "requests.memory" = "${_budget.request_memory_mib}Mi"
        "limits.memory" = "${_budget.limit_memory_mib}Mi"
        "requests.storage" = "${_budget.storage_gib}Gi"
    }
}
