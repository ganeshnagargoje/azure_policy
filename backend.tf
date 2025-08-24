terraform {    
    backend "azurerm" {
      resource_group_name  = "dev-resources"
      storage_account_name = "ganeshdevday0413496"
      container_name       = "tfstate"
      key                  = "dev.terraform.tfstate"
    }
}