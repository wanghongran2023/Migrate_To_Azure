# Migrate To Azure

In this project, we are going to migrate a simple application to Azure.

## Resource Utilization

| Resources Name | Details | Price |
|----------|----------|
| 1. Azure Resource Group | Location: West US | free |
| 2. Azure Database for PostgreSQL Flexible Server | SKU: B_Standard_B1ms<br/>Storage: 32 GB<br/>Backup Retention: 7 days | 30 USD |
| 3. Azure App Service Plan | SKU: P0v3 (PremiumV3)<br/>OS: Linux | 65USD |
| 4. Azure Service Bus | SKU: Standard | 30USD |
| 5. Azure Storage Account | Replication: LRS<br/>Access Tier: Cool | 10USD |
| 6. Azure Linux Web App | OS: Linux | included in 3 |
| 7. Azure Linux Function App | OS: Linux | included in 3 |

## Set up

In this project, we will use github action flow and Terraform to build the infratructure and deploy the applicatiuon automatically, to use the workflow, you should set up all the secret and variables below:

  - The app registration should have the Contributor role, and GitHub federated access should be set up for the repository repo:wanghongran2023/Migrate_To_Azure:environment:Production and repo:wanghongran2023/Migrate_To_Azure:ref:refs/heads/main. 

| Secret Name | Content |
|----------|----------|
| 1. DB_SERVER_USER		| Account used to access DB Server |
| 2. DB_SERVER_PASSWORD	| Password used to access DB Server |
| 3. TENANT_ID 			| Microsoft Entra ID -> Tenant ID |
| 4. SUBSCRIPTION_ID		| Subscriptions -> Subscriptions ID |
| 5. SP_CLIENT_ID		| Application -> Application (client) ID |
| 6. SP_CLIENT_SECRET	        | Application Secret -> Value |

| Variables Name | Content |
|----------|----------|
| 1. APP_NAME			| Name for App service |
| 2. DB_NAME			| Name for DB |
| 3. DB_SERVER_NAME		| Name for DB Server |
| 4. RESOURCE_GROUP_LOCATION	| Location for resource group, like west US |
| 5. RESOURCE_GROUP_NAME	| Name for resource group |
| 6. STORAGE_ACCOUNT_NAME		| Name for Storage Account |
| 7. FUNCTION_NAME		| Name for function app |
| 8. SERVICEBUS_NAME		| Name for services |

## Deploy Infra and APp

  - Run the Infrastructure Construction Workflow. This workflow will use GitHub secrets and variables to update Terraform variables and deploy the storage account, database, resource group, and app services ... to Azure
  - However, you still need to check the binding of servicebus and function trigger
