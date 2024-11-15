variable "resource_group_name" {}

variable "location" {
  default = "West Europe"
}

variable "create_data_disks" {
  type = bool
  default = true
}

variable create_nfs_share{
  type = bool
  default = true
}

variable "data_disks" {
  type = map(object({
    name         = string
    disk_size_gb = number
    lun          = number
  }))
  default = {
    disk01 = {
      name         = "disk1"
      disk_size_gb = 10
      lun          = 10
    }
  }
}

variable vnet_cidr{
  type = list
  default = ["10.0.2.0/24"]
}
variable "subnet_addr_space" {
  type = list
  default = [
    "10.0.2.0/26",
    "10.0.2.64/26"
  ]
}

variable "nfs_capacity" {
  type = number
  default = 100
}
