
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
  address_space       = var.vnet_cidr
  location            = azurerm_resource_group.public_vm_resource_group.location
  resource_group_name = azurerm_resource_group.public_vm_resource_group.name
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.public_vm_resource_group.name
  virtual_network_name = azurerm_virtual_network.vm_network.name
  address_prefixes     = [var.subnet_addr_space[0]]
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
    source      = "./provision.sh"
    destination = "/tmp/provision.sh"
    connection {
      type        = "ssh"
      user        = "adminuser"
      private_key = file("./key")
      host        = self.public_ip_address
      timeout     = "2m"
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

# Because there is file provisioner we need to create this resource before the VM
resource "azurerm_network_security_rule" "vm-public-ssh-access" {
  name                        = "AllowAnyCustom22Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = 22
  source_address_prefix       = "*"
  # destination_address_prefix  = var.subnet_addr_space
  destination_address_prefix = azurerm_network_interface.public.private_ip_address
  resource_group_name         = azurerm_resource_group.public_vm_resource_group.name
  network_security_group_name = azurerm_network_security_group.vm_sg_ssh.name
}

### Add data disks
module "add_data_disks" {
  source = "./modules/azure-data_disks"
  count = var.data_disks != null ? 1 : 0
  vm_id = azurerm_linux_virtual_machine.public_vm.id
  data_disks = var.data_disks
  rg_name = azurerm_resource_group.public_vm_resource_group.name
  location = azurerm_resource_group.public_vm_resource_group.location
}

module "create_nfs_share" {
  source = "./modules/azure-nfs4"
  # count = var.create_nfs_share ? 1 : 0
  count = var.nfs_capacity != null ? 1 : 0
  storage_account_name ="fileshare"
  nfs_share_name = "nfsdata"
  rg_name = azurerm_resource_group.public_vm_resource_group.name
  location = azurerm_resource_group.public_vm_resource_group.location
  nfs_capacity =var.nfs_capacity
  vm_nw_name = azurerm_virtual_network.vm_network.name
  virtual_network_id = azurerm_virtual_network.vm_network.id
  subnet_addr_space = var.subnet_addr_space[1]
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