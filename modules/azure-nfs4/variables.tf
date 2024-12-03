variable storage_account_name {
  default = "fileshare"
}

variable "nfs_share_name" {
  default = "nfsdata"
}

variable "rg_name" {
}

variable "location" {
}

variable "nfs_capacity" {
  type = number
    validation {
    condition = var.nfs_capacity >= 100
    error_message = "Minimum capacity is 100GB"
  }
}

variable "vm_nw_name" {
}
variable "subnet_addr_space" {
  
}

variable "virtual_network_id" {
  
}
