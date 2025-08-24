variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant (Entra ID) ID"
}

variable "client_id" {
  type        = string
  description = "Azure AD application (service principal) client ID"
}

variable "client_secret" {
  type        = string
  description = "Azure AD application (service principal) client secret"
  sensitive   = true
}

#variable for locations
variable "allowed_locations" {
  type        = list(string)
  description = "Azure allowed locations"
  default     = ["canadacentral" ,"canadaeast"]
}

#variable for tags
variable "allowed_tags" {
  type        = list(string)
  description = "Resource tags"
  default     = [ "department", "project" ]
}

#variable for vm sizes
variable "allowed_vm_sizes" {
  type        = list(string)
  description = "Allowed VM sizes"
  default     = ["Standard_B1ls", "Standard_B1s"]
}