resource "azurerm_resource_group" "rg" {
  name     = "lrn-rg"
  location = "eastus"
  tags = {
    department = "IT"
    #project    = "AzurePolicy"
  }
}