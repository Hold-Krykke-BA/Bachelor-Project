variable "rg_name" {
  description = "Resource Group Name"
  type        = string
}

variable "location" {
  description = "Azure Resource Location"
  type        = string
}

variable "sql_location" {
  description = "Alternative location for SQL services due to quotas"
  type        = string
}

variable "mssql_username" {
  description = "Username for login to the MSSQL server"
  sensitive   = true
  type        = string
}

variable "mssql_password" {
  description = "Password for login to the MSSQL server"
  sensitive   = true
  type        = string
}