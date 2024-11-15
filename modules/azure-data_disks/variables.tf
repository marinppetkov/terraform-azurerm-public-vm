variable "rg_name" {
  
}

variable "location" {
  
}

variable vm_id {
    description = "ID of the VM where the datadisks will be attached"
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