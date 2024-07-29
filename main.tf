
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "public_vm_resource_group" {
  name     = var.resource_group_name
  location = var.location
}

### Network infrastructure

resource "azurerm_virtual_network" "vm_network" {
  name                = "vm-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.public_vm_resource_group.location
  resource_group_name = azurerm_resource_group.public_vm_resource_group.name
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.public_vm_resource_group.name
  virtual_network_name = azurerm_virtual_network.vm_network.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "vm_public_ip" {
  name                = "vm-pip"
  resource_group_name = azurerm_resource_group.public_vm_resource_group.name
  location            = azurerm_resource_group.public_vm_resource_group.location
  allocation_method   = "Static"
}
resource "azurerm_network_interface" "public" {
  name                = "vm-public-nic"
  resource_group_name = azurerm_resource_group.public_vm_resource_group.name
  location            = azurerm_resource_group.public_vm_resource_group.location

  ip_configuration {
    name                          = "public"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }
}

### Virtual machine instance

resource "azurerm_linux_virtual_machine" "public_vm" {
  name                = "ubuntu-machine"
  resource_group_name = azurerm_resource_group.public_vm_resource_group.name
  location            = azurerm_resource_group.public_vm_resource_group.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.public.id
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("./key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    # offer     = "0001-com-ubuntu-server-jammy"
    # sku       = "22_04-lts"
    offer   = "0001-com-ubuntu-server-focal"
    sku     = "20_04-lts"
    version = "latest"
  }
}

# ### Data Disk
resource "azurerm_managed_disk" "data_disk" {
  for_each             = var.data_disks
  name                 = each.value.name
  location             = azurerm_resource_group.public_vm_resource_group.location
  resource_group_name  = azurerm_resource_group.public_vm_resource_group.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = each.value.disk_size_gb
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attachment" {
  for_each           = var.data_disks
  managed_disk_id    = azurerm_managed_disk.data_disk[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.public_vm.id
  lun                = each.value.lun
  caching            = "ReadWrite"
}

# ### N-S Security
# resource "azurerm_network_security_group" "vm_sg_ssh" {
#   name                = "vm-public-ssh-access"
#   location            = azurerm_resource_group.public_vm_resource_group.location
#   resource_group_name = azurerm_resource_group.public_vm_resource_group.name
# }
# resource "azurerm_network_interface_security_group_association" "public_ssh" {
#   network_interface_id      = azurerm_network_interface.public.id
#   network_security_group_id = azurerm_network_security_group.vm_sg_ssh.id
# }

# resource "azurerm_network_security_rule" "vm-public-ssh-access" {
#   name                        = "ssh"
#   priority                    = 110
#   direction                   = "Inbound"
#   access                      = "Deny"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_range      = 22
#   source_address_prefix       = "*"
#   # destination_address_prefix  = azurerm_linux_virtual_machine.public_vm.private_ip_address
#   destination_address_prefix = azurerm_linux_virtual_machine.public_vm.public_ip_address
#   resource_group_name         = azurerm_resource_group.public_vm_resource_group.name
#   network_security_group_name = azurerm_network_security_group.vm_sg_ssh.name
# }

