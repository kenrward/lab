locals {
  vms = {
    win2022-dc   = { role = "dc", name = "lab-dc01" }
    win2022-app1 = { role = "member", name = "lab-app1" }
  }
}
