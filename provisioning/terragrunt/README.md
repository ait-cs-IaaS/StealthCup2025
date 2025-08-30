# Terragrunt Deployment

This repository contains the infrastructure code for deploying and managing resources using Terragrunt and Terraform.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) installed
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured

## AWS Credentials Setup

To set up your AWS credentials using the AWS CLI, follow these steps:

1. Open a terminal.
2. Run the following command and follow the prompts to enter your AWS Access Key ID, Secret Access Key, and default region:

    ```sh
    aws configure
    ```

3. Verify that your credentials are correctly configured by running:

    ```sh
    aws sts get-caller-identity
    ```

## Terraform state setup

Follow the instructions on: <https://git-service.ait.ac.at/sct-cyberrange/packages/terraform-state>

## Deploying the Infrastructure

To deploy the infrastructure using Terragrunt, follow these steps:

1. Navigate to the directory containing the `terragrunt.hcl` file.

    ```sh
    cd provisioning/terragrunt
    ```

2. Initialize the Terraform configuration:

    ```sh
    terragrunt init
    ```

3. Apply the Terraform configuration to create the resources:

    ```sh
    terragrunt apply
    ```

    This command will show a plan of the changes to be made and prompt you to confirm before applying them.

## Destroying the Infrastructure

To destroy the infrastructure and remove all resources created by Terragrunt, follow these steps:

1. Navigate to the directory containing the  file.

    ```sh
    cd provisioning/terragrunt
    ```

2. Destroy the Terraform-managed infrastructure:

    ```sh
    terragrunt destroy
    ```

    This command will show a plan of the resources to be destroyed and prompt you to confirm before proceeding.

## Additional Information

For more details on using Terragrunt, refer to the [Terragrunt documentation](https://terragrunt.gruntwork.io/docs/).

For more details on using Terraform, refer to the [Terraform documentation](https://www.terraform.io/docs/).

[Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
