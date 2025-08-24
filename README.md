# Terraform Azure Policy: Enforce Required Tags

This project uses Terraform to:
- Create an Azure custom Policy Definition that denies resources missing specific tags.
- Optionally create a Resource Group for validation.

The policy enforces that every resource includes two tags provided in variables: department and project (configurable).


## Repository layout

- backend.tf — Remote state backend configuration for Azure Storage.
- provider.tf — Provider configuration using a service principal via variables.
- variables.tf — Input variables (subscription, tenant, client credentials, and allowed tags).
- terraform.tfvars — Example values for variables. Do not commit real secrets.
- main.tf — Data sources (subscription).
- policies.tf — Custom policy definition that denies resources missing required tags.
- rg.tf — Example resource group with tags to test the policy behavior.


## Prerequisites

- Azure subscription and permissions to assign roles and create policy definitions.
- Azure CLI 2.59+ and Terraform 1.9+.
- An Azure AD application (service principal) and client secret, or use Azure CLI login.


## Configure remote state backend

The backend in backend.tf expects an existing resource group, storage account, and container. Create them (or change names in backend.tf) before `terraform init`.

Example using Azure CLI:

```bash
az group create --name dev-resources --location canadacentral
az storage account create --name ganeshdevday0413496 --resource-group dev-resources --location canadacentral --sku Standard_LRS --kind StorageV2
az storage container create --name tfstate --account-name ganeshdevday0413496
```


## Authentication and variables

This configuration expects service principal credentials via variables (see terraform.tfvars). You can also use environment variables instead of committing secrets:

On Windows (Command Prompt):

```bat
setx ARM_SUBSCRIPTION_ID "<your-subscription>"
setx ARM_TENANT_ID "<your-tenant>"
setx ARM_CLIENT_ID "<youur-client>"
setx ARM_CLIENT_SECRET "<your-secret>"
```

Then update provider.tf to prefer environment authentication, or keep current variable-driven configuration and supply values via `-var` or a local `.tfvars` file that you do not commit.

Security note: Do not commit real client secrets to source control. The terraform.tfvars file in this repo is an example only and should be replaced locally with safe values or environment variables.


## Required Azure RBAC permissions

To create a policy definition at subscription scope, the principal used by Terraform must have at least the built-in role “Resource Policy Contributor” at that subscription (or Owner).

Assign the role with Azure CLI (replace the object id with your SP’s object id if different):

```bash
az role assignment create --assignee-object-id your-client-id --assignee-principal-type ServicePrincipal --role "Resource Policy Contributor" --scope /subscriptions/youur-subscription_id
```

If your organization prefers using the application (client) id:

```bash
az role assignment create --assignee XXXXX-XXXX-XXXX-XXXX-XXXX --assignee-principal-type ServicePrincipal --role "Resource Policy Contributor" --scope /subscriptions/youur-subscription_id
```

After assigning roles, wait 1–2 minutes for propagation.


## What the policy does

The policy definition in `policies.tf` uses `jsonencode` to send Azure Policy rule JSON. It denies resource creation when either of the configured tags is missing. Important detail: `exists` must be a boolean (`false`), not a string (`"false"`).

Example rule shape (rendered by Terraform):

```json
{
  "if": {
    "anyOf": [
      { "field": "tags[department]", "exists": false },
      { "field": "tags[project]",    "exists": false }
    ]
  },
  "then": { "effect": "deny" }
}
```

The specific tag keys are taken from variable `allowed_tags`; defaults are `["department","project"]`.


## Policy assignment is required

A policy definition alone does nothing until it is assigned to a scope. To enforce it at the subscription:

Add a new Terraform file, for example `policy_assignment.tf`, with:

```hcl
resource "azurerm_policy_assignment" "enforce_required_tags" {
  name                 = "enforce-required-tags"
  display_name         = "Enforce required tags (subscription)"
  scope                = data.azurerm_subscription.primary.id
  policy_definition_id = azurerm_policy_definition.allowed_tag_policy.id
  enforcement_mode     = "Default"
}
```

Notes:
- This policy is not parameterized; it uses the tag keys baked from variables at plan time.
- If you prefer management group scope, set `management_group_id` on the definition and set `scope` to the management group id on the assignment. Ensure RBAC at that scope.


## Usage

1) Set credentials:
- Either export `ARM_*` environment variables, or
- Edit `terraform.tfvars` locally with your real values (do not commit).

2) Initialize:

```bash
terraform init
```

3) Validate and review:

```bash
terraform fmt -check
terraform validate
terraform plan
```

4) Apply:

```bash
terraform apply
```

If you receive `AuthorizationFailed` for `Microsoft.Authorization/policyDefinitions/write`, grant the role as shown earlier and retry after a short delay.


## Test the policy

After you add the policy assignment, try to apply `rg.tf` as provided. The `project` tag is commented out there to demonstrate a denial. With the assignment in place, creating the resource group should be denied by Azure Policy. Uncomment the `project` tag and apply again to succeed.


## Common issues and fixes

- 403 AuthorizationFailed on `policyDefinitions/write`:
  Grant `Resource Policy Contributor` (or `Owner`) to the service principal at the subscription or management group scope.

- Role `'Policy Contributor'` doesn't exist:
  Use `"Resource Policy Contributor"` (correct built-in role) or `"Owner"`.

- Backend init errors (No such host container or account):
  Ensure the storage account, resource group, and container exist and names match `backend.tf`; or update `backend.tf` accordingly.

- `exists` value treated as string:
  Use `exists = false` (boolean) in the policy_rule.

- Wrong scope:
  Assign the policy at the same or higher scope where you want enforcement (subscription or management group). Resource group scope will not allow creating a definition at subscription.


## Cleanup

To remove created resources including the policy assignment and definition:

```bash
terraform destroy
```

If you are using a shared remote state account and container, do not delete those unless they are dedicated for this project.


## License

MIT (or your preferred license).