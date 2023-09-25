# Station Design Decisions

## Creation of Terraform Cloud projects

Creating Terraform Cloud projects has been left out of the implementation of Station because of the following
- Normally you would deploy Station with multiple environments in mind ("dev", "test", "prod"). If one of these were responsible for the creation of the project, and you deleted that environment later on, you would loose the Project or the deletion would error as workspaces exist in it.

## Creation of Git repositories

Left out of the implementation for the following reasons
- Normally you would deploy Station with multiple environments in mind. If one of these were responsible for the creation of the repository, and you deleted that environment later on, you would loose the repository.

## DRY when creating an abstraction on top of provider resources

When creating a resource from a resource that already exists, like `azuread_application`, only insert type constraints on Station's input variable. This is to reduce the amount of duplicate code. The submodule's variable should only take one input `azuread_application` with type `type = any`.

Look at Station's sub-module `application/` for example. Relevant files:
- `variables.tf`: See variable `applications`'s type constraint.
- `applications.tf`
- `application/variables.tf`
- `application/azuread_application.tf`

This approach makes optionals unbelievably easy to work with; any optional variable from Station is automatically assigned as `null`. Inputting `null` on another optional variable will fly with Terraform. This is because `nullable` is `true` by default. Take a look at `application/azuread_application.tf` for examples, notice the lack of `try()` and `can()` expressions.

