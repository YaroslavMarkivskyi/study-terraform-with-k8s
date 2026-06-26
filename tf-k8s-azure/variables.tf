variable "location" {
  type        = string
  default     = "westeurope"
  description = "Region where resources will be created"
}

variable "resource_group_name" {
  type        = string
  default     = "k8s-the-hard-way-rg"
  description = "Name of the resource group"
}

variable "vnet_cidr" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
  description = "Address space for the virtual network"
}

variable "public_subnet_cidr" {
  type        = list(string)
  default     = ["10.0.1.0/24"]
  description = "CIDR for the public subnet (Jumpbox)"
}

variable "private_subnet_cidr" {
  type        = list(string)
  default     = ["10.0.2.0/24"]
  description = "CIDR for the private subnet (K8s Cluster)"
}

variable "admin_username" {
  type        = string
  default     = "azureuser"
  description = "Administrator user for SSH access"
}

variable "internal_nodes" {
  type = map(object({
    size = string
    ip   = string
    disk = number
  }))
  default = {
    "server" = { size = "Standard_B1ms", ip = "10.0.2.10", disk = 20 }
    "node-0" = { size = "Standard_B1ms", ip = "10.0.2.11", disk = 20 }
    "node-1" = { size = "Standard_B1ms", ip = "10.0.2.12", disk = 20 }
  }
  description = "Configuration of internal cluster nodes with fixed IPs"
}