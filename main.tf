
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
  address_space       = ["10.0.2.0/24"]
  location            = azurerm_resource_group.public_vm_resource_group.location
  resource_group_name = azurerm_resource_group.public_vm_resource_group.name
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.public_vm_resource_group.name
  virtual_network_name = azurerm_virtual_network.vm_network.name
  address_prefixes     = [var.subnet_addr_space]
}

resource "azurerm_public_ip" "vm_public_ip" {
  name                = "vm-pip"
  resource_group_name = azurerm_resource_group.public_vm_resource_group.name
  location            = azurerm_resource_group.public_vm_resource_group.location
  allocation_method   = "Static"
  # sku                 = "Standard" ### This is for the nat gateway
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
  provisioner "file" {
    source      = "./mount.sh"
    destination = "/tmp/mount.sh"
    connection {
      type        = "ssh"
      user        = "adminuser"
      private_key = file("./key")
      host        = self.public_ip_address
      timeout     = "7m"
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    # offer   = "0001-com-ubuntu-server-focal"
    # sku     = "20_04-lts"
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
  # timeouts {
  #   create = 45
  # }
}
### Extension

resource "azurerm_virtual_machine_extension" "deployment_script" {
  name                 = "mount_data_disks"
  virtual_machine_id   = azurerm_linux_virtual_machine.public_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
 {
  "commandToExecute": "sudo bash /tmp/mount.sh"
 }
SETTINGS


  tags = {
    environment = "Production"
  }
  depends_on = [azurerm_virtual_machine_data_disk_attachment.data_disk_attachment]
}
### N-S Security
resource "azurerm_network_security_group" "vm_sg_ssh" {
  name                = "vm-public-ssh-access"
  location            = azurerm_resource_group.public_vm_resource_group.location
  resource_group_name = azurerm_resource_group.public_vm_resource_group.name
}
resource "azurerm_network_interface_security_group_association" "public_ssh" {
  network_interface_id      = azurerm_network_interface.public.id
  network_security_group_id = azurerm_network_security_group.vm_sg_ssh.id
}
### Notes
/*
https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview
 Network security groups are processed after Azure translates a public IP address to a 
private IP address for inbound traffic, and before Azure translates a private IP address to a 
public IP address for outbound traffic
*/
resource "azurerm_network_security_rule" "vm-public-ssh-access" {
  name                        = "AllowAnyCustom22Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 22
  source_address_prefix       = "*"
  destination_address_prefix  = var.subnet_addr_space
  resource_group_name         = azurerm_resource_group.public_vm_resource_group.name
  network_security_group_name = azurerm_network_security_group.vm_sg_ssh.name
}

### load balancer
# resource "azurerm_public_ip" "example" {
#   name                = "PublicIPForLB"
#   resource_group_name = azurerm_resource_group.public_vm_resource_group.name
#   location            = azurerm_resource_group.public_vm_resource_group.location
#   allocation_method   = "Static"
#   # sku = "Standard" ### This is for the nat gateway
# }

# resource "azurerm_lb" "example" {
#   name                = "TestLoadBalancer"
#   resource_group_name = azurerm_resource_group.public_vm_resource_group.name
#   location            = azurerm_resource_group.public_vm_resource_group.location
#   # sku = "Standard" ### This is for the nat gateway
#   frontend_ip_configuration {
#     name                 = "PublicIPAddress"
#     public_ip_address_id = azurerm_public_ip.example.id
#   }
# }

# resource "azurerm_lb_backend_address_pool" "example" {
#   loadbalancer_id = azurerm_lb.example.id
#   name            = "acctestpool"
# }

# resource "azurerm_network_interface_backend_address_pool_association" "example" {
#   network_interface_id    = azurerm_network_interface.public.id
#   ip_configuration_name   = azurerm_network_interface.public.ip_configuration[0].name
#   backend_address_pool_id = azurerm_lb_backend_address_pool.example.id
# }

# resource "azurerm_lb_rule" "lb_rules" {
#   loadbalancer_id                = azurerm_lb.example.id
#   name                           = "LBRule"
#   protocol                       = "Tcp"
#   frontend_port                  = 80
#   backend_port                   = 80
#   frontend_ip_configuration_name = azurerm_lb.example.frontend_ip_configuration[0].name
#   backend_address_pool_ids       = [azurerm_lb_backend_address_pool.example.id]
# }
# output lb_ip {
#   value = azurerm_public_ip.example.ip_address
# }
# https://learn.microsoft.com/en-us/azure/load-balancer/load-balancer-outbound-connections#2-associate-a-nat-gateway-to-the-subnet
# resource "azurerm_nat_gateway" "example" {
#   name                = "example-NatGateway"
#   resource_group_name = azurerm_resource_group.public_vm_resource_group.name
#   location            = azurerm_resource_group.public_vm_resource_group.location
#   sku_name            = "Standard"
# }

# resource "azurerm_nat_gateway_public_ip_association" "example" {
#   nat_gateway_id       = azurerm_nat_gateway.example.id
#   public_ip_address_id = azurerm_public_ip.vm_public_ip.id
# }

# resource "azurerm_subnet_nat_gateway_association" "example" {
#   subnet_id      = azurerm_subnet.vm_subnet.id
#   nat_gateway_id = azurerm_nat_gateway.example.id
# }
### Must solve issue https://stackoverflow.com/questions/68036097/azure-loadbalancer-can-the-virtual-machines-in-backendpool-retain-public-ip