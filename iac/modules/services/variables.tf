variable "rg_name" {
  description = "Resource Group Name"
  type        = string
}

variable "location" {
  description = "Azure Resource Location"
  type        = string
}

variable "storage_account" {
  description = "Storage account for use with services. \"rr0dev0sa1\""
  type        = any
}

variable "ingress_application_gateway" {
  description = "Application Gateway for AKS ingress (AGIC)"
  type        = any
}

variable "aks_location" {
  description = "Alternative location for AKS due to quotas"
  type        = string
}