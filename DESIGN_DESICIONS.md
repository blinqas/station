# Station Design Decisions

## Creation of Terraform Cloud projects

Creating Terraform Cloud projects has been left out of the implementation of Station because of the following
- Normally you would deploy Station with multiple environments in mind ("dev", "test", "prod"). If one of these were responsible for the creation of the project, and you deleted that environment later on, you would loose the Project or the deletion would error as workspaces exist in it.

## Creation of Git repositories

Left out of the implementation for the following reasons
- Normally you would deploy Station with multiple environments in mind. If one of these were responsible for the creation of the repository, and you deleted that environment later on, you would loose the repository.


