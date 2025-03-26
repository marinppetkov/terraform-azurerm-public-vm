resource "azurerm_storage_share_file" "example" {
  name             = "collector.yaml"
  storage_share_id = var.nfs_share_id
  source           = "collector.yml"
}

variable "nfs_share_id" {
}