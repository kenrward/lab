locals {
  vms = var.vms

  ready_check_path = (
    trimspace(var.ready_path) != ""
    ? (startswith(var.ready_path, "/") ? var.ready_path : "/${var.ready_path}")
    : ""
  )
}