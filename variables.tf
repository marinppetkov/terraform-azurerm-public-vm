variable "resource_group_name" {}

variable "location" {
  default = "West Europe"
}

variable "data_disks"{
    type = map(object({
      name = string
      disk_size_gb = number
      lun = number
    }))
    default = {}
}