

# https://learn.microsoft.com/en-us/azure/storage/files/storage-files-quick-create-use-linux

resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}

resource "azurerm_storage_account" "sa_nfs_share" {
  name                          = "${lower(var.storage_account_name)}${random_integer.suffix.id}"
  location                      = var.location
  resource_group_name           = var.rg_name
  account_tier                  = "Premium"
  account_replication_type      = "LRS"
  public_network_access_enabled = true ### Need to execute terraform inside the vmnet or have network peering. Can be done with agents if using HCP Terraform
  account_kind                  = "FileStorage"
  https_traffic_only_enabled    = false # Secure transfer required setting to Disabled
  tags = {
    environment = "lab"
  }
}

### Looks like squash settings option is missing
### https://github.com/hashicorp/terraform-provider-azurerm/issues/14173

resource "azurerm_storage_share" "nfs_share" {
  name                  = var.nfs_share_name
  storage_account_name  = azurerm_storage_account.sa_nfs_share.name
  quota                 = var.nfs_capacity
  enabled_protocol      = "NFS"

}

data "azurerm_virtual_network" "vm_network" {
  name                = var.vm_nw_name
  resource_group_name = var.rg_name
}

resource "azurerm_subnet" "sa_subnet" {
  name                 = "storageAccSubnet"
  resource_group_name  = var.rg_name
  virtual_network_name = data.azurerm_virtual_network.vm_network.name
  address_prefixes     = [var.subnet_addr_space]
  private_endpoint_network_policies = "Enabled" ## Will use acl to filter traffic to the PE
  service_endpoints    = ["Microsoft.Storage"]
}
resource "azurerm_private_endpoint" "sa_private_endpoint" {
  custom_network_interface_name = "sa_pr_endpoint_interface"
  name                          = "sa_pr_endpoint"
  location                      = var.location
  resource_group_name           = var.rg_name
  subnet_id                     = azurerm_subnet.sa_subnet.id

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_zone.id]
  }
  private_service_connection {
    is_manual_connection              = false
    name                              = "sa_privateserviceconnection"
    private_connection_resource_id    = azurerm_storage_account.sa_nfs_share.id
    subresource_names                 = ["file"]
  }
}
resource "azurerm_private_dns_zone" "dns_zone" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name           = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vm_net_zone_link" {
  name                  = "vm_net_zone_link"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone.name
  virtual_network_id    = data.azurerm_virtual_network.vm_network.id
}

### Linux vm
# sudo apt-get -y update
# sudo apt-get install nfs-common
# sudo mkdir -p /mount/filesharetestmarin/sharename
# sudo mount -t nfs filesharetestmarin.file.core.windows.net:/filesharetestmarin/sharename /mount/filesharetestmarin/sharename -o vers=4,minorversion=1,sec=sys,nconnect=4