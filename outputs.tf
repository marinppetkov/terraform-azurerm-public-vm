output "public_VM_address" {
  description = "VM public ip address"
  value       = azurerm_linux_virtual_machine.public_vm.public_ip_address
}

## No op - test policy cost estimate HCP terraform US (soft mandatory)
## No op hard mandatory policy
## no op - successful policy for eu and us
## no op - successful policy set advisory mode us and eu
## no op - fail policy set advisory mode us and eu