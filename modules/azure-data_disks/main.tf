# ### Data Disk
resource "azurerm_managed_disk" "data_disk" {
  for_each             = var.data_disks
  name                 = each.value.name
  location             = var.location
  resource_group_name  = var.rg_name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = each.value.disk_size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attachment" {
  for_each           = var.data_disks
  managed_disk_id    = azurerm_managed_disk.data_disk[each.key].id
  virtual_machine_id = var.vm_id
  lun                = each.value.lun
  caching            = "ReadWrite"
}


resource "azurerm_virtual_machine_extension" "deployment_script" {
  name                 = "mount_data_disks"
  virtual_machine_id   = var.vm_id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
 {
  "commandToExecute": "sudo bash /tmp/provision.sh"
 }
SETTINGS


  tags = {
    environment = "Production"
  }
  depends_on = [azurerm_virtual_machine_data_disk_attachment.data_disk_attachment]
}


