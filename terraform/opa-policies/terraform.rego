package terraform.analysis

deny[msg] {
  input.resource_changes[_].change.after.cpu > 16
  msg = "Refuse VM with more than 16 CPUs"
}
