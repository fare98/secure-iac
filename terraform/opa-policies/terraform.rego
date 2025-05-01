package terraform.analysis

deny[msg] {
  input.resource_changes[_].change.after.cpu > 8
  msg = "No VM may have more than 8 vCPUs in the home-lab."
}