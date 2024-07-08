output "public_VM_address" {
  description = "VM public ip address"
  value       = azurerm_linux_virtual_machine.public_vm.public_ip_address
}

## no op - fail policy set advisory mode us and eu
## no op - successful policy set advisory mode us and eu
## no op - successful policy set soft mandatory for us and eu
## no op - fail policy set soft mandatory for us and eu
## no op - fail policy set hard mandatory for us and eu
## no op - successful policy set hard mandatory for us and eu