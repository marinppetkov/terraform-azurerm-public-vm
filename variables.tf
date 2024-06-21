variable "resource_group_name" {
  default = "marin-tests"
}

variable "location" {
  default = "West Europe"
}

variable "enable_data_disk" {
  default = true
  type    = bool
}

variable "data_disks" {
  type    = map # Dynamic map or map(any)
  default = {}
}

# variable "data_disks"{
#     type = object({
#       name = string,
#       disk_size_gb = number
#     })
# }