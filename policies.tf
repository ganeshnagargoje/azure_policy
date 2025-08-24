# Policy to enforce required tags on resources
resource "azurerm_policy_definition" "allowed_tag_policy" {
  name         = "allowed-tag-policy"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Enforce required tags on resources"
  description  = "This policy ensures that all resources have the required tags."

  policy_rule = jsonencode({
    if = {
        anyOf = [
          {
            field = "tags[${var.allowed_tags[0]}]",
            exists = false
          },
          {
            field = "tags[${var.allowed_tags[1]}]",
            exists = false
          }
        ]
    }
    then = {
      effect = "deny"
    }
  })
}
# Policy to enforce required vm sizes
resource "azurerm_policy_definition" "allowed_vm_size_policy" {
  name         = "allowed-vm-size-policy"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Enforce allowed VM sizes"
  description  = "This policy ensures that only allowed VM sizes are used."

  policy_rule = jsonencode({
    if = {
      anyOf = [
        {
          field = "Microsoft.Compute/virtualMachines/sku.name",
          notIn = ["${var.allowed_vm_sizes}"]
        }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

# Policy to enforce allowed locations
resource "azurerm_policy_definition" "allowed_locations_policy" {
  name         = "allowed-locations-policy"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Enforce allowed locations"
  description  = "This policy ensures that resources are deployed in allowed locations."

  policy_rule = jsonencode({
    if = {
      not = {
        field = "location",
        in    = ["${var.allowed_locations}"]
      }
    }
    then = {
      effect = "deny"
    }
  })
}
