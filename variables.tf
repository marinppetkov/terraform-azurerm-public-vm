variable "resource_group_name" {}

variable "location" {
  default = "West Europe"
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
variable "subnet_addr_space" {
  default = "10.0.2.0/26"
}
