# Migrate To Azure

In this project, we are going to migrate a simple application to Azure.

## Comparision between Existing and Refactor Architecture

#### Existing Architecture:

The previous system is a monolithic one, where the frontend and backend functionality for notifications is combined into a single function. While this approach is easy to manage, it may cause issues under heavy usage.

Currently, the notification function consists of three main parts: sending emails to all attendees, updating the database, and redirecting to the notifications page. Combining these steps into a single function works fine when there are only a few attendees. However, if the number of attendees is significant, such as 200, the email-sending process might take several minutes to complete. Since the redirection step depends on the completion of the email-sending process, users may experience long waiting times during which the webpage remains unresponsive. This would negatively impact the user experience.

#### Refactor Architecture:

After refactoring, the function is divided into frontend and backend components, with a service bus used to transfer messages between them. The frontend only needs to send a single notification to the queue, update the database, and redirect to the notifications page. Afterward, users can immediately begin using the frontend for other tasks, such as sending a new notification.

Messages are delivered to trigger the function app via the service bus with retries. All time-consuming tasks are processed by the function app, which operates seamlessly from the user's perspective. This approach ensures that the web system maintains consistent response times and performance, even under heavy usage.


## Resource Utilization

In this project, we will use Azure resources, including a resource group, web app, function app, service plan, service bus and queue, storage account, and Azure Database for PostgreSQL Flexible Server.

We will deploy the frontend web application and backend API to an Azure App Service and use a service bus and queue to decouple their interaction. The database will be migrated to Azure Database for PostgreSQL Flexible Server. A storage account is required for deploying the function app, and the resource group is used to organize and group all the resources.

 - To deploy the frontend and backend, we chose to use Linux App Service instead of virtual machines. This decision was based on the application's light usage and the environment requirements. By using App Service, Azure handles most of the complex tasks, such as scaling, which significantly reduces operational complexity.
 - If we were to use virtual machines, the cost would remain fixed regardless of usage, making it less cost-effective for this system. Additionally, deploying to virtual machines would require managing the operating system, which increases operational overhead.
 - To further improve cost efficiency, we decided to share a single service plan between the web app and the function app. While this may impact performance slightly, the system's light usage ensures that the performance impact will not be significant.

## Cost Estimation

| Resources Name | Details | Price |
|----------|----------|----------|
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

