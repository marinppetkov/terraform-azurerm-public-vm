output "public_VM_address" {
  description = "VM public ip address"
  value       = azurerm_linux_virtual_machine.public_vm.public_ip_address
}

## No op - test policy cost estimate HCP terraform US (soft mandatory)
## No op hard mandatory policy